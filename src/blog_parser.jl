@isdefined(FactorGraph)    || include(string(@__DIR__, "/factor_graph.jl"))
@isdefined(ParfactorGraph) || include(string(@__DIR__, "/parfactor_graph.jl"))

"""
	model_to_blog(pfg::ParfactorGraph, io::IO = stdout)

Convert a parfactor model to BLOG (Bayesian logic) syntax.
The BLOG string is written to `io`.
"""
function model_to_blog(pfg::ParfactorGraph, io::IO = stdout)
	### Logvars
	all_lvs = Set{LogVar}()
	for prv in prvs(pfg)
		!isempty(logvars(prv)) && push!(all_lvs, logvars(prv)...)
	end
	for lv in all_lvs
		write(io, string("type", " ", name(lv), ";\n"))
	end
	!isempty(all_lvs) && write(io, "\n")
	for lv in all_lvs
		s = string(
			"guaranteed", " ", name(lv), " ", join(domain(lv), ", "),
			";\n"
		)
		write(io, s)
	end
	!isempty(all_lvs) && write(io, "\n")

	### PRVs
	for prv in prvs(pfg)
		s = string(
			"random", " ",
			range_to_type(range(prv)), " ",
			name(prv),
			isempty(logvars(prv)) ? "" :
				string("(", join(map(x -> name(x), logvars(prv)), ", "), ")"),
			";\n"
		)
		write(io, s)
	end
	write(io, "\n")

	### Parfactors
	for pf in parfactors(pfg)
		non_counted_lvs = Set{LogVar}()
		lv_to_var = Dict{LogVar, AbstractString}()
		curr_var_num = 1
		for prv in prvs(pf)
			if isnothing(counted_over(prv)) || !(pf in counted_in(prv))
				lvs = logvars(prv)
			else
				lvs = filter(x -> x != counted_over(prv), logvars(prv))
				lv_to_var[counted_over(prv)] = string("X", curr_var_num)
				curr_var_num += 1
			end
			!isempty(lvs) && push!(non_counted_lvs, lvs...)
		end
		for lv in non_counted_lvs
			lv_to_var[lv] = string("X", curr_var_num)
			curr_var_num += 1
		end
		lvs_sorted = sort([(k, v) for (k, v) in lv_to_var], by = x -> x[2])
		s = string(
			isempty(non_counted_lvs) ? "factor" : "parfactor", " ",
			join(map(x -> string(name(x[1]), " ", x[2]), lvs_sorted), ", "),
			isempty(lvs_sorted) ? "" : ". ",
			"MultiArrayPotential",
			"[[", join(potentials_ordered(pf), ", "), "]]",
			"\n\t"
		)
		write(io, s)

		arglist = []
		for prv in prvs(pf)
			if isnothing(counted_over(prv)) || !(pf in counted_in(prv))
				s = string(
					name(prv),
					isempty(logvars(prv)) ? "" :
						string("(", join(map(x -> lv_to_var[x], logvars(prv)), ", "), ")")
				)
			else
				@assert length(logvars(prv)) == 1 # May be handled in the future
				lv = logvars(prv)[1]
				s = string(
					"#(", name(lv), " ", lv_to_var[lv],
					")[", name(prv), "(", lv_to_var[lv], ")]"
				)
			end
			push!(arglist, s)
		end
		s = string("(", join(arglist, ", "), ")", ";\n\n")
		write(io, s)
	end
end

"""
	range_to_type(range::Vector)::String

Convert a range of values to a string representing the type of the values.
"""
function range_to_type(range::Vector)::String
	@assert !isempty(range) && all(x -> typeof(x) == typeof(range[1]), range)
	t = typeof(range[1])
	if t == Bool
		return "Boolean"
	else
		error("Unsupported type '$t'!")
	end
end