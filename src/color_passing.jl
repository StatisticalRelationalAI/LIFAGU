"""
	color_passing(fg::FactorGraph, node_colors = Dict{RandVar, Int}(), factor_colors = Dict{Factor, Int}())::Tuple{Dict{RandVar, Int}, Dict{Factor, Int}}

Apply the color passing algorithm introduced by Kersting et al. (2009) to a
given factor graph `fg`.
Return a tuple of two dictionaries, the first mapping each random variable
to a group of random variables and the second mapping each factor to a group
of factors.

## References
K. Kersting, B. Ahmadi, and S. Natarajan.
Counting belief propagation.
UAI, 2009.

## Examples
```jldoctest
julia> fg = FactorGraph();
julia> nc, fc = color_passing(fg)
```
"""
function color_passing(
	fg::FactorGraph,
	node_colors = Dict{RandVar, Int}(),
	factor_colors = Dict{Factor, Int}()
)::Tuple{Dict{RandVar, Int}, Dict{Factor, Int}}
	initcolors!(node_colors, factor_colors, fg)

	while true
		changed = false
		f_signatures = Dict{Factor, Vector{Int}}()
		for f in factors(fg)
			f_signatures[f] = []
			for node in rvs(f)
				push!(f_signatures[f], node_colors[node])
			end
			push!(f_signatures[f], factor_colors[f])
		end

		changed |= assigncolors!(factor_colors, f_signatures, fg)

		rv_signatures = Dict{RandVar, Vector{Tuple{Int,Int}}}()
		for node in rvs(fg)
			rv_signatures[node] = []
			for f in edges(fg, node)
				push!(rv_signatures[node], (factor_colors[f], rvpos(f, node)))
			end
			sort!(rv_signatures[node])
			push!(rv_signatures[node], (node_colors[node], 0))
		end

		changed |= assigncolors!(node_colors, rv_signatures, fg)

		!changed && break
	end

	return node_colors, factor_colors
end

"""
	initcolors!(node_colors::Dict{RandVar, Int}, factor_colors::Dict{Factor, Int}, fg::FactorGraph)

Initialize the color dictionaries `node_colors` and `factor_colors` for the
factor graph `fg`.
"""
function initcolors!(
	node_colors::Dict{RandVar, Int},
	factor_colors::Dict{Factor, Int},
	fg::FactorGraph
)
	assigncolors!(node_colors, Dict{RandVar, Vector{Tuple{Int, Int}}}(), fg)
	assigncolors!(factor_colors, Dict{Factor, Vector{Int}}(), fg)
end

"""
	assigncolors!(node_colors::Dict{RandVar, Int}, rv_signatures::Dict{RandVar, Vector{Tuple{Int, Int}}}, fg::FactorGraph)::Bool

Re-assign colors to the random variables in `fg` based on the signatures
`rv_signatures`.
"""
function assigncolors!(
	node_colors::Dict{RandVar, Int},
	rv_signatures::Dict{RandVar, Vector{Tuple{Int, Int}}},
	fg::FactorGraph
)::Bool
	colors = Dict()
	current_color = 0
	changed = false
	for rv in rvs(fg)
		key = isempty(rv_signatures) ? (range(rv), evidence(rv)) : rv_signatures[rv]
		if !haskey(colors, key)
			colors[key] = current_color
			current_color += 1
		end
		if haskey(node_colors, rv) && node_colors[rv] != colors[key]
			changed = true
		end
		node_colors[rv] = colors[key]
	end
	return changed
end

"""
	assigncolors!(factor_colors::Dict{Factor, Int}, f_signatures::Dict{Factor, Vector{Int}}, fg::FactorGraph)::Bool

Re-assign colors to the factors in `fg` based on the signatures `f_signatures`.
"""
function assigncolors!(
	factor_colors::Dict{Factor, Int},
	f_signatures::Dict{Factor, Vector{Int}},
	fg::FactorGraph
)::Bool
	colors = Dict()
	current_color = numrvs(fg)
	changed = false
	for f in factors(fg)
		key = isempty(f_signatures) ? potentials(f) : f_signatures[f]
		if !haskey(colors, key)
			colors[key] = current_color
			current_color += 1
		end
		if haskey(factor_colors, f) && factor_colors[f] != colors[key]
			changed = true
		end
		factor_colors[f] = colors[key]
	end
	return changed
end