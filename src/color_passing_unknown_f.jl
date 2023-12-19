@isdefined(color_passing) || include(string(@__DIR__, "/color_passing.jl"))

"""
	unknown_color_passing(
		fg::FactorGraph,
		cp::Function = color_passing,
		thresh::AbstractFloat = 1.0,
		node_colors = Dict{RandVar, Int}(),
		factor_colors = Dict{Factor, Int}()
	)::Tuple{Dict{RandVar, Int}, Dict{Factor, Int}}

Apply the color passing algorithm for factor graphs containing unknown factors
on `fg`.
Return a tuple of two dictionaries, the first mapping each random variable
to a group of random variables and the second mapping each factor to a group
of factors.
"""
function unknown_color_passing(
	fg::FactorGraph,
	cp::Function = color_passing,
	thresh::AbstractFloat = 1.0,
	node_colors = Dict{RandVar, Int}(),
	factor_colors = Dict{Factor, Int}()
)::Tuple{Dict{RandVar, Int}, Dict{Factor, Int}}
	@assert 0.0 <= thresh <= 1.0 "Threshold must be in [0, 1]!"

	initcolors!(node_colors, factor_colors, fg)
	unknown_f = unknown_factors(fg)

	# Assign each unknown factor a unique color
	col = numfactors(fg) + 1
	for f in unknown_f
		factor_colors[f] = col
		col += 1
	end

	# Find possible candidates
	candidates = Dict{Factor, Vector{Factor}}()
	symmetry_cache = Dict{Tuple{Factor, Factor}, Bool}()
	for f1 in unknown_f
		for f2 in factors(fg)
			f1 != f2 || continue
			if possibly_identical(fg, f1, f2, symmetry_cache)
				if is_unknown(f2)
					factor_colors[f2] = factor_colors[f1]
				else
					!haskey(candidates, f1) && (candidates[f1] = [])
					push!(candidates[f1], f2)
				end
			end
		end
	end

	# Assign new colors to candidates
	for (f1, other) in candidates
		lppi = largest_ppi_subset(fg, other, symmetry_cache)
		length(lppi) / length(other) >= thresh || continue
		for f2 in lppi
			factor_colors[f2] = factor_colors[f1]
		end
		# All factors in lppi have idential potentials
		f1.potentials = first(lppi).potentials
	end

	return cp(fg, node_colors, factor_colors)
end

"""
	possibly_identical(
		fg::FactorGraph,
		f1::Factor,
		f2::Factor,
		sym_cache::Dict{Tuple{Factor, Factor}, Bool}
	)::Bool

Check whether `f1` and `f2` are possibly identical, that is whether
1. their neighborhoods are symmetric and
2. at least one of them is unknown, or both share the same potentials.
"""
function possibly_identical(
	fg::FactorGraph,
	f1::Factor,
	f2::Factor,
	sym_cache::Dict{Tuple{Factor, Factor}, Bool}
)::Bool
	if !(is_unknown(f1) || is_unknown(f2) || potentials(f1) == potentials(f2))
		return false
	end

	if !haskey(sym_cache, (f1, f2))
		is_symmetric = is_symmetric_neighborhood(fg, f1, f2)
		sym_cache[(f1, f2)] = is_symmetric
		sym_cache[(f2, f1)] = is_symmetric
	end

	return sym_cache[(f1, f2)]
end

"""
	is_symmetric_neighborhood(fg::FactorGraph, f1::Factor, f2::Factor)::Bool

Check whether `f1` and `f2` are connected to the same number of random
variables and whether for each random variable in the neighborhood of `f1`,
there is a random variable in the neighborhood of `f2` connected to the
same number of factors, with identical range, and with identical evidence.

For example, consider a factor `f1` connected to random variable `A` and
factor `f2` connected to random variable `B` with both `A` and `B` having
no evidence and being Boolean:
- If `A` is connected to `f1`, `f3` and `f4` and `B` to `f2` and `f3`,
`false` is returned.
- If `A` is connected to `f1`, `f3` and `f4` and `B` to `f2`, `f3` and `f5`,
`false` is returned.
- If `A` is connected to `f1`, `f3` and `f4` and `B` to `f2`, `f3` and `f4`,
`true` is returned.
"""
function is_symmetric_neighborhood(fg::FactorGraph, f1::Factor, f2::Factor)::Bool
	length(edges(fg, f1)) == length(edges(fg, f2)) || return false

	e2 = copy(edges(fg, f2))
	for rv1 in edges(fg, f1)
		flag = false
		for rv2 in e2
			if range(rv1) == range(rv2) && evidence(rv1) == evidence(rv2) &&
					length(edges(fg, rv1)) == length(edges(fg, rv2))
				deleteat!(e2, findfirst(x -> x == rv2, e2))
				flag = true
				break
			end
		end
		flag || return false
	end

	return isempty(e2)
end

"""
	largest_ppi_subset(
		fg::FactorGraph,
		set::Vector{Factor},
		sym_cache::Dict{Tuple{Factor, Factor}, Bool}
	)::Set{Factor}

Return the largest subset of factors in `set` that are pairwise
possibly identical in `fg`.
"""
function largest_ppi_subset(
	fg::FactorGraph,
	set::Vector{Factor},
	sym_cache::Dict{Tuple{Factor, Factor}, Bool}
)::Set{Factor}
	length(set) <= 1 && return Set(set)

	ppi_sets = Dict()
	for i in eachindex(set), j in i:length(set)
		f1, f2 = set[i], set[j]
		f1 != f2 || continue
		!haskey(ppi_sets, f1) && (ppi_sets[f1] = Set([f1]))
		!haskey(ppi_sets, f2) && (ppi_sets[f2] = Set([f2]))
		if possibly_identical(fg, f1, f2, sym_cache)
			push!(ppi_sets[f1], f2)
			push!(ppi_sets[f2], f1)
		end
	end

	largest = Set{Factor}()
	for s in values(ppi_sets)
		length(s) > length(largest) && (largest = s)
	end

	return largest
end