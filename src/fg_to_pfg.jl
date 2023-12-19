@isdefined(FactorGraph)    || include(string(@__DIR__, "/factor_graph.jl"))
@isdefined(ParfactorGraph) || include(string(@__DIR__, "/parfactor_graph.jl"))

"""
	groups_to_pfg(fg::FactorGraph, node_colors::Dict{RandVar, Int}, factor_colors::Dict{Factor, Int}, commutative_args_cache::Dict = Dict(), hist_cache::Dict = Dict())::Tuple{ParfactorGraph, Dict{RandVar, String}}

Convert the groups in a factor graph `fg` to a parfactor graph.
Return a tuple consisting of the parfactor graph and a dictionary which
contains a mapping from each random variable to an individual object.

## References
M. Luttermann, T. Braun, R. Möller, and M. Gehrke
Colour Passing Revisited: Lifted Model Construction with Commutative Factors
AAAI, 2024.
"""
function groups_to_pfg(
	fg::FactorGraph,
	node_colors::Dict{RandVar, Int},
	factor_colors::Dict{Factor, Int},
	commutative_args_cache::Dict = Dict(),
	hist_cache::Dict = Dict()
)::Tuple{ParfactorGraph, Dict{RandVar, String}}
	pfg = ParfactorGraph()
	rv_groups, factor_groups = colors_to_groups(node_colors, factor_colors)
	rv_group_to_prv = Dict()
	f_group_to_pf = Dict()

	### Create placeholder parfactor graph (to have the edges in advance)
	for (rv_group_id, rv_group) in rv_groups
		r = range(rv_group[1]) # All rvs in group have the same range
		if length(rv_group) > 1
			lvs = [LogVar(string("L", rv_group_id), length(rv_group))]
		else
			lvs = []
		end
		prv = PRV(string("R", rv_group_id), r, lvs, nothing, [])
		rv_group_to_prv[rv_group_id] = prv
		add_prv!(pfg, prv)
	end
	for (f_group_id, f_group) in factor_groups
		pf = Parfactor(string("pf", f_group_id), Vector{PRV}(), [])
		f_group_to_pf[f_group_id] = pf
		add_parfactor!(pfg, pf)
		for f in f_group, rv in rvs(f)
			prv = rv_group_to_prv[node_colors[rv]]
			!has_edge(pfg, prv, pf) && push!(pf.prvs, prv) # Only add once
			add_edge!(pfg, prv, pf)
		end
	end

	### Add real logvars and potentials
	for (f_group_id, f_group) in factor_groups
		pf = f_group_to_pf[f_group_id]
		# Take any fg in the group as all have the same number of neighbors
		num_rvs = length(rvs(f_group[1]))
		num_prvs = length(prvs(pf))

		# Set logvars
		rv_groups_vals = collect(values(rv_groups))
		for i in eachindex(rv_groups_vals)
			for j in i+1:length(rv_groups_vals)
				if has_identical_logvar(fg, rv_groups_vals[i], rv_groups_vals[j])
					id1 = node_colors[rv_groups_vals[i][1]]
					id2 = node_colors[rv_groups_vals[j][1]]
					rv_group_to_prv[id2].logvars = rv_group_to_prv[id1].logvars
				end
			end
		end

		# Set potentials
		if num_rvs == num_prvs # Number of neighbors unchanged: No CRV
			pf.potentials = f_group[1].potentials
		else # Number of neighbors has changed: CRV needed
			@assert haskey(commutative_args_cache, f_group[1])
			# Commutative args are the same for all factors in group
			commutative_rvs = commutative_args_cache[f_group[1]]
			# Color is identical for all rvs in group
			prv = rv_group_to_prv[node_colors[commutative_rvs[1]]]
			@assert length(logvars(prv)) == 1
			prv.counted_over = logvars(prv)[1]
			push!(prv.counted_in, pf)
			# Move CRV to first position to match potentials
			pf.prvs = [prv; setdiff(prvs(pf), [prv])]
			counted_ps = hist_cache[f_group[1]][Set(commutative_rvs)]
			new_potentials = Dict{String, AbstractFloat}()
			for (config, pot) in counted_ps
				# pot is a multi-set containing exactly one value
				hist = replace(string(config[1]), "," => ";")
				rest = length(config) > 1 ? string(config[2:end]) : ""
				rest = replace(rest, "(" => "", ",)" => "")
				key = string(hist, isempty(rest) ? "" : ", ", rest)
				new_potentials[key] = collect(pot)[1]
			end
			pf.potentials = new_potentials
		end
	end

	rv_to_i = Dict() # Maps names from fg to pfg for queries
	lvdom_indices = Dict()
	for rv in rvs(fg)
		prv = rv_group_to_prv[node_colors[rv]]
		!haskey(lvdom_indices, prv) && (lvdom_indices[prv] = 1)
		if isempty(logvars(prv))
			rv_to_i[rv] = name(prv)
		else
			lv = logvars(prv)[1]
			individuum = domain(lv)[lvdom_indices[prv]]
			rv_to_i[rv] = string(name(prv), "(", individuum, ")")
		end
		lvdom_indices[prv] += 1
	end

	return pfg, rv_to_i
end

"""
	colors_to_groups(node_colors::Dict{RandVar, Int}, factor_colors::Dict{Factor, Int})::Tuple{Dict, Dict}

Convert colors returned by a color passing algorithm to groups of random
variables and factors, respectively.
"""
function colors_to_groups(
	node_colors::Dict{RandVar, Int},
	factor_colors::Dict{Factor, Int}
)::Tuple{Dict, Dict}
	rv_groups, factor_groups = Dict(), Dict()
	for (rv, color) in node_colors
		if !haskey(rv_groups, color)
			rv_groups[color] = []
		end
		push!(rv_groups[color], rv)
	end
	for (f, color) in factor_colors
		if !haskey(factor_groups, color)
			factor_groups[color] = []
		end
		push!(factor_groups[color], f)
	end
	return rv_groups, factor_groups
end

"""
	list_domain_sizes(pf::Parfactor)::Vector{Int}

List all domain sizes occurring in all of the PRVs of the argument list of
the given parfactor `pf`.
"""
function list_domain_sizes(pf::Parfactor)::Vector{Int}
	dom_sizes = []
	for prv in prvs(pf)
		if isempty(logvars(prv)) # Propositional randvar
			push!(dom_sizes, 1)
		else # Paramaterized randvar
			for lv in logvars(prv)
				push!(dom_sizes, domain_size(lv))
			end
		end
	end
	return dom_sizes
end

"""
	has_identical_logvar(fg::FactorGraph, rv_group1::Vector, rv_group2::Vector)::Bool

Check whether two groups of random variables represented by two PRVs should
share the same logvar.
"""
function has_identical_logvar(
	fg::FactorGraph,
	rv_group1::Vector,
	rv_group2::Vector
)::Bool
	length(rv_group1) == length(rv_group2) || return false

	factors_1 = Set{Factor}()
	for rv in rv_group1, f in edges(fg, rv)
		push!(factors_1, f)
	end
	factors_2 = Set{Factor}()
	for rv in rv_group2, f in edges(fg, rv)
		push!(factors_2, f)
	end

	mappings = Dict{RandVar, RandVar}()
	for f in intersect(factors_1, factors_2)
		rvs1 = filter(rv -> has_edge(fg, rv, f), rv_group1)
		rvs2 = filter(rv -> has_edge(fg, rv, f), rv_group2)
		@assert length(rvs1) == 1 && length(rvs2) == 1
		!haskey(mappings, rvs1[1]) && (mappings[rvs1[1]] = rvs2[1])
		!haskey(mappings, rvs2[1]) && (mappings[rvs2[1]] = rvs1[1])
		mappings[rvs1[1]] == rvs2[1] || return false
		mappings[rvs2[1]] == rvs1[1] || return false
	end

	return true
end