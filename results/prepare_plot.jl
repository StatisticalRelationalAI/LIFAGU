using Statistics

@isdefined(nanos_to_millis) || include(string(@__DIR__, "/../src/helper.jl"))

"""
	prepare_times(file::String)

Parse the times of the BLOG inference output, build averages and
write the results into a new `.csv` file.
"""
function prepare_times(file::String)
	averages = Dict()
	open(file, "r") do io
		readline(io) # Remove header
		for line in readlines(io)
			cols = split(line, ",")
			engine = cols[1]
			name = cols[2]
			if engine == "fove.LiftedVarElim" && contains(name, "-grt")
				continue
			end
			time = nanos_to_millis(parse(Float64, cols[12]))
			d = match(r"d=(\d+)-", name)[1]
			haskey(averages, engine) || (averages[engine] = Dict())
			haskey(averages[engine], d) || (averages[engine][d] = [])
			push!(averages[engine][d], time)
		end
	end
	open(replace(file, ".csv" => "-prepared.csv"), "a") do io
		write(io, "engine,d,min_time,max_time,mean_time,median_time,std\n")
		for (engine, d) in averages
			for (d, times) in d
				s = string(
					engine, ",",
					d, ",",
					minimum(times), ",",
					maximum(times), ",",
					mean(times), ",",
					median(times), ",",
					std(times), "\n"
				)
				write(io, s)
			end
		end
	end
end

"""
	prepare_errors(file::String)

Parse the Kulback-Leibler divergences for each domain, build averages and
write the results into a new `.csv` file.
"""
function prepare_errors(file::String)
	averages = Dict()
	open(file, "r") do io
		readline(io) # Remove header
		for line in readlines(io)
			cols = split(line, ",")
			instance = cols[1]
			d = match(r"d=(\d+)$", instance)[1]
			kl_divergence = parse(Float64, cols[18])
			haskey(averages, d) || (averages[d] = [])
			push!(averages[d], kl_divergence)
		end
	end
	open(replace(file, ".csv" => "-prepared.csv"), "a") do io
		write(io, "d,min_kl_div,max_kl_div,mean_kl_div,median_kl_div,std\n")
		for (d, divs) in averages
			s = string(
				d, ",",
				minimum(divs), ",",
				maximum(divs), ",",
				mean(divs), ",",
				median(divs), ",",
				std(divs), "\n"
			)
			write(io, s)
		end
	end
end

prepare_times(string(@__DIR__, "/_stats.csv"))
prepare_errors(string(@__DIR__, "/results.csv"))
