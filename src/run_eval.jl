using Random

@isdefined(FactorGraph)           || include(string(@__DIR__, "/factor_graph.jl"))
@isdefined(ParfactorGraph)        || include(string(@__DIR__, "/parfactor_graph.jl"))
@isdefined(color_passing)         || include(string(@__DIR__, "/color_passing.jl"))
@isdefined(unknown_color_passing) || include(string(@__DIR__, "/color_passing_unknown_f.jl"))
@isdefined(groups_to_pfg)         || include(string(@__DIR__, "/fg_to_pfg.jl"))
@isdefined(blog_to_model)         || include(string(@__DIR__, "/blog_parser.jl"))
@isdefined(blog_to_queries)       || include(string(@__DIR__, "/queries.jl"))
@isdefined(delete_potentials!)    || include(string(@__DIR__, "/helper.jl"))

function run_eval(
	input_dir=string(@__DIR__, "/../instances/input/"),
	output_dir=string(@__DIR__, "/../instances/output/"),
	logfile=string(@__DIR__, "/../results/results.csv"),
	jar_file=string(@__DIR__, "/../instances/ljt-v1.0-jar-with-dependencies.jar"),
	seed=123
)
	Random.seed!(seed)
	logfile_exists = isfile(logfile)

	csv_cols = string(
		"instance,", # name of the input instance
		"query,", # name of the query
		"n_rvs,", # number of random variables
		"n_factors,", # number of factors
		"n_max_args,", # max number of arguments of a factor
		"n_unknown_factors,", # number of unknown factors
		"perc_unknown_factors,", # percentage of unknown factors
		"n_rvs_compressed,", # number of random variables after compression
		"n_factors_compressed,", # number of factors after compression
		"perc_reduced_size,", # percentage of reduction in size (size = n_rvs + n_factors)
		"largest_group_size,", # size of the largest group
		"num_groups,", # number of groups
		"score,", # similarity score
		"n_error_extra,", # number of errors where too much grouping happened
		"n_error_missing,", # number of errors where too little grouping happened
		"distribution_ground_truth,", # distribution of the ground truth
		"distribution_compressed,", # distribution of the compressed model
		"kl_divergence_distributions", # KL divergence between the distributions
		"\n"
	)

	open(logfile, "a") do io
		!logfile_exists && write(io, csv_cols)
		for (root, dirs, files) in walkdir(input_dir)
			for f in files
				(!occursin(".DS_Store", f) && !occursin("README", f) && !occursin(".gitkeep", f)) || continue
				fpath = string(root, endswith(root, "/") ? "" : "/", f)
				@info "=> Processing file '$fpath'..."
				fg, queries = load_from_file(fpath)
				fg_grt = deepcopy(fg)
				n_rvs = numrvs(fg)
				n_factors = numfactors(fg)
				n_max_args = maximum([length(rvs(f)) for f in factors(fg)])
				# Delete 5%-10% of factors, randomly chosen
				delete_potentials!(fg, ceil(Int, rand(5:10) / 100 * n_factors))
				n_unknown_factors = length(filter(f -> is_unknown(f), factors(fg)))
				perc_unknown_factors = n_unknown_factors / n_factors

				@info "Running 'color_passing'..."
				node_c_grt, factor_c_grt = color_passing(fg_grt)
				@info "Running 'unknown_color_passing'..."
				node_c, factor_c = unknown_color_passing(fg, color_passing, 0.0)

				n_rvs_compressed = length(unique(values(node_c)))
				n_factors_compressed = length(unique(values(factor_c)))
				perc_reduced_size = (n_rvs_compressed + n_factors_compressed) /
					(n_rvs + n_factors)

				score, err_extra, err_missing = similarity_score(
					node_c_grt,
					factor_c_grt,
					node_c,
					factor_c
				)

				@info "Converting outputs to blog file..."
				pfg_grt, rv_to_ind_grt = groups_to_pfg(fg_grt, node_c_grt, factor_c_grt)
				pfg, rv_to_ind = groups_to_pfg(fg, node_c, factor_c)
				largest_group_size = maximum(
					[isempty(logvars(prv)) ? 1 :
						reduce(+, map(lv -> length(domain(lv)), logvars(prv)))
					for prv in prvs(pfg)]
				)
				num_groups = length(prvs(pfg))
				io_buffer_grt = IOBuffer()
				io_buffer = IOBuffer()
				model_to_blog(pfg_grt, io_buffer_grt)
				model_to_blog(pfg, io_buffer)
				model_str_grt = String(take!(io_buffer_grt))
				model_str = String(take!(io_buffer))
				for (idx, query) in enumerate(queries)
					new_f_grt = string(output_dir, replace(f, ".ser" => "-q$idx-grt.blog"))
					open(new_f_grt, "w") do out_io
						write(out_io, model_str_grt)
						write(out_io, join(query_to_blog(query, rv_to_ind_grt), "\n"))
					end
					new_f = string(output_dir, replace(f, ".ser" => "-q$idx.blog"))
					open(new_f, "w") do out_io
						write(out_io, model_str)
						write(out_io, join(query_to_blog(query, rv_to_ind), "\n"))
					end

					@info "\tVariable Elimination for query $query..."
					# Execution of .jar file measures time automatically
					execute_inference_algo(jar_file, new_f_grt, "ve.VarElimEngine")
					@info "\tLifted Variable Elimination for query $query..."
					dist_grt = execute_inference_algo(jar_file, new_f_grt, "fove.LiftedVarElim")
					dist = execute_inference_algo(jar_file, new_f, "fove.LiftedVarElim")

					if !haskey(dist_grt, "timeout") && !haskey(dist, "timeout")
						kl = kl_divergence(
							dist_to_fn(dist_grt),
							dist_to_fn(dist),
							[0, 1],
						)
					else
						kl = "timeout"
					end

					write(io, join([
						replace(f, ".ser" => ""),
						query,
						n_rvs,
						n_factors,
						n_max_args,
						n_unknown_factors,
						round(perc_unknown_factors, digits=2),
						n_rvs_compressed,
						n_factors_compressed,
						round(perc_reduced_size, digits=2),
						largest_group_size,
						num_groups,
						round(score, digits=2),
						err_extra,
						err_missing,
						dist_to_str(dist_grt),
						dist_to_str(dist),
						kl
					], ","), "\n")
					flush(io)
				end
			end
		end
	end
end

"""
	run_with_timeout(command, timeout::Int = 60)

Run an external command with a timeout. If the command does not finish within
the specified timeout, the process is killed and `timeout` is returned.
"""
function run_with_timeout(command, timeout::Int = 60)
	out = Pipe()
	cmd = run(pipeline(command, stdout=out); wait=false)
	close(out.in)
	for _ in 1:timeout
		!process_running(cmd) && return read(out, String)
		sleep(1)
	end
	kill(cmd)
	return "timeout"
end

"""
	execute_inference_algo(
		jar_file::String,
		input_file::String,
		engine::String,
		output_dir=string(@__DIR__, "/../results/"),
	)::Dict{String, Float64}

Execute the `.jar` file with the specified inference engine on the specified
BLOG input file.
"""
function execute_inference_algo(
	jar_file::String,
	input_file::String,
	engine::String,
	output_dir=string(@__DIR__, "/../results/"),
)::Dict{String, Float64}
	@assert engine in [
		"jt.JTEngine",
		"fojt.LiftedJTEngine",
		"ve.VarElimEngine",
		"fove.LiftedVarElim"
	]
	cmd = `java -jar $jar_file -e $engine -o $output_dir $input_file`
	res = run_with_timeout(cmd)
	return res == "timeout" ? Dict("timeout" => 1) : parse_blog_output(res)
end

"""
	parse_blog_output(o::AbstractString)::Dict{String, Float64}

Retrieve the probability distribution from the output of the BLOG inference
algorithm.
"""
function parse_blog_output(o::AbstractString)::Dict{String, Float64}
	dist = Dict{String, Float64}()
	flag = false
	for line in split(o, "\n")
		if flag && !isempty(strip(line))
			prob, val = split(replace(lstrip(line), r"\s" => " "), " ")
			dist[val] = round(parse(Float64, prob), digits=4)
		end
		occursin("Distribution of values for", line) && (flag = true)
	end
	return dist
end

"""
	dist_to_str(d::Dict{String, Float64})::String

Convert a distribution for a random variable to a string that can be shown
in the logfile.
"""
function dist_to_str(d::Dict{String, Float64})::String
	haskey(d, "timeout") && return "timeout"
	return join(["$k=$v" for (k, v) in d], ";")
end

"""
	dist_to_fn(d::Dict{String, Float64})::Function

Convert a distribution for a Boolean random variable to a function
(for the purpose of computing the KL divergence).
"""
function dist_to_fn(d::Dict{String, Float64})::Function
	# Note that this works only for Boolean random variables
	return function(x)
		return x == 0 ? d["false"] : d["true"]
	end
end

"""
	kl_divergence(p::Function, q::Function)::Float64

Compute the Kullback-Leibler divergence between two probability distributions
`p` and `q` over the given domain `d`.
"""
function kl_divergence(p::Function, q::Function, d::Vector)::Float64
	return sum([p(x) * log(p(x) / q(x)) for x in d])
end

run_eval()
