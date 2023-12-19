@isdefined(PRV)         || include(string(@__DIR__, "/prvs.jl"))
@isdefined(Parfactor)   || include(string(@__DIR__, "/parfactors.jl"))
@isdefined(FactorGraph) || include(string(@__DIR__, "/factor_graph.jl"))

"""
	ParfactorGraph

Struct for a parfactor graph.

## Examples
```jldoctest
julia> fg = ParfactorGraph();
```
"""
struct ParfactorGraph
	prvs::Vector{PRV}
	prv_edges::Dict{PRV, Vector{Parfactor}}
	parfactors::Vector{Parfactor}
	parfactor_edges::Dict{Parfactor, Vector{PRV}}
	ParfactorGraph() = new([], Dict(), [], Dict())
end

"""
	prvs(pfg::ParfactorGraph)::Vector{PRV}

Return all paramerized random variables in the given factor graph `fg`.
"""
function prvs(pfg::ParfactorGraph)::Vector{PRV}
	return pfg.prvs
end

"""
	parfactors(pfg::ParfactorGraph)::Vector{Parfactor}

Return all parfactors in the given factor graph `fg`.
"""
function parfactors(pfg::ParfactorGraph)::Vector{Parfactor}
	return pfg.parfactors
end

"""
	numprvs(pfg::ParfactorGraph)::Int

Return the number of paramerized random variables in the given
factor graph `fg`.
"""
function numprvs(pfg::ParfactorGraph)::Int
	return length(pfg.prvs)
end

"""
	numparfactors(pfg::ParfactorGraph)::Int

Return the number of parfactors in the given factor graph `fg`.
"""
function numparfactors(pfg::ParfactorGraph)::Int
	return length(pfg.parfactors)
end

"""
	numnodes(pfg::ParfactorGraph)::Int

Return the number of nodes (i.e., the number of parfactors plus the number
of paramerized random variables) in the given factor graph `fg`.
"""
function numnodes(pfg::ParfactorGraph)::Int
	return length(pfg.prvs) + length(pfg.parfactors)
end

"""
	contains_prv(pfg::ParfactorGraph, prv::PRV)::Bool

Return `true` if the parfactor graph `pfg` contains the paramerized random
variable `prv`, and `false` otherwise.
"""
function contains_prv(pfg::ParfactorGraph, prv::PRV)::Bool
	return any(x -> x == prv, pfg.prvs)
end

"""
	contains_parfactor(pfg::ParfactorGraph, f::Parfactor)::Bool

Return `true` if the parfactor graph `pfg` contains the parfactor `f`, and
`false` otherwise.
"""
function contains_parfactor(pfg::ParfactorGraph, f::Parfactor)::Bool
	return any(x -> x == f, pfg.parfactors)
end

"""
	edges(pfg::ParfactorGraph, prv::PRV)::Vector{Parfactor}

Return the parfactors that are connected to the paramerized random variable
`prv` in the given parfactor graph `pfg`.
"""
function edges(pfg::ParfactorGraph, prv::PRV)::Vector{Parfactor}
	return get(pfg.prv_edges, prv, [])
end

"""
	edges(pfg::ParfactorGraph, f::Parfactor)::Vector{PRV}

Return the paramerized random variables that are connected to the parfactor
`f` in the given parfactor graph `pfg`.
"""
function edges(pfg::ParfactorGraph, f::Parfactor)::Vector{PRV}
	return get(pfg.parfactor_edges, f, [])
end

"""
	add_prv!(pfg::ParfactorGraph, prv::PRV)::Bool

Add the paramerized random variable `prv` to the given parfactor graph `pfg`.
Return `true` if the paramerized random variable was successfully added, and
`false` otherwise (i.e., `prv` was already in `pfg` before).
"""
function add_prv!(pfg::ParfactorGraph, prv::PRV)::Bool
	if !contains_prv(pfg, prv)
		push!(pfg.prvs, prv)
		pfg.prv_edges[prv] = []
		return true
	end
	return false
end

"""
	rem_prv!(pfg::ParfactorGraph, prv::PRV)::Bool

Remove the paramerized random variable `prv` from the given parfactor graph
`pfg`. Return `true` if the paramerized random variable was successfully
removed, and `false` otherwise (i.e., `prv` was not contained before).
"""
function rem_prv!(pfg::ParfactorGraph, prv::PRV)::Bool
	if contains_prv(pfg, prv)
		deleteat!(pfg.prvs, findall(x -> x == prv, pfg.prvs))
		return true
	end
	return false
end

"""
	add_parfactor!(pfg::ParfactorGraph, f::Parfactor)::Bool

Add the parfactor `f` to the given parfactor graph `pfg`.
Return `true` if the parfactor was successfully added, and
`false` otherwise (i.e., `f` was already in `pfg` before).
"""
function add_parfactor!(pfg::ParfactorGraph, f::Parfactor)::Bool
	if !contains_parfactor(pfg, f)
		push!(pfg.parfactors, f)
		pfg.parfactor_edges[f] = []
		return true
	end
	return false
end

"""
	rem_parfactor!(pfg::ParfactorGraph, f::Parfactor)::Bool

Remove the parfactor `f` from the given parfactor graph `pfg`.
Return `true` if the parfactor was successfully removed, and
`false` otherwise (i.e., `f` was not contained before).
"""
function rem_parfactor!(pfg::ParfactorGraph, f::Parfactor)::Bool
	if contains_factor(pfg, f)
		deleteat!(pfg.parfactors, findall(x -> x == f, pfg.parfactors))
		return true
	end
	return false
end

"""
	has_edge(pfg::ParfactorGraph, prv::PRV, f::Parfactor)::Bool

Return `true` if the parfactor graph `pfg` contains an edge between the
paramerized random variable `prv` and the parfactor `f`, and `false`
otherwise.
"""
function has_edge(pfg::ParfactorGraph, prv::PRV, f::Parfactor)::Bool
	return f in edges(pfg, prv) && prv in edges(pfg, f)
end

"""
	has_edge(pfg::ParfactorGraph, f::Parfactor, prv::PRV)::Bool

Return `true` if the parfactor graph `pfg` contains an edge between the
parfactor `f` and the paramerized random variable `prv`, and `false`
otherwise.
"""
function has_edge(pfg::ParfactorGraph, f::Parfactor, prv::PRV)::Bool
	return has_edge(pfg, prv, f)
end

"""
	add_edge!(pfg::ParfactorGraph, prv::PRV, f::Parfactor)::Bool

Add an edge between the paramerized random variable `prv` and the parfactor
`f` to the given parfactor graph `pfg`. Return `true` if the edge was
successfully added, and `false` otherwise (i.e., the edge was already in
`pfg` before).
"""
function add_edge!(pfg::ParfactorGraph, prv::PRV, f::Parfactor)::Bool
	if !has_edge(pfg, prv, f)
		push!(pfg.prv_edges[prv], f)
		push!(pfg.parfactor_edges[f], prv)
		return true
	end
	return false
end

"""
	add_edge!(pfg::ParfactorGraph, f::Parfactor, prv::PRV)::Bool

Add an edge between the parfactor `f` and the paramerized random variable
`prv` to the given parfactor graph `pfg`. Return `true` if the edge was
successfully added, and `false` otherwise (i.e., the edge was already in
`pfg` before).
"""
function add_edge!(pfg::ParfactorGraph, f::Parfactor, prv::PRV)::Bool
	return add_edge!(pfg, prv, f)
end

"""
	rem_edge!(pfg::ParfactorGraph, prv::PRV, f::Parfactor)::Bool

Remove the edge between the paramerized random variable `prv` and the
parfactor `f` from the given parfactor graph `pfg`. Return `true` if the
edge was successfully removed, and `false` otherwise (i.e., the edge was
not contained before).
"""
function rem_edge!(pfg::ParfactorGraph, prv::PRV, f::Parfactor)::Bool
	if has_edge(pfg, prv, f)
		deleteat!(
			pfg.prv_edges[prv],
			findfirst(x -> x == f, pfg.prv_edges[prv])
		)
		deleteat!(
			pfg.parfactor_edges[f],
			findfirst(x -> x == prv, pfg.parfactor_edges[f])
		)
		return true
	end
	return false
end

"""
	rem_edge!(pfg::ParfactorGraph, f::Parfactor, prv::PRV)::Bool

Remove the edge between the parfactor `f` and the paramerized random
variable `prv` from the given parfactor graph `pfg`. Return `true` if the
edge was successfully removed, and `false` otherwise (i.e., the edge was
not contained before).
"""
function rem_edge!(pfg::ParfactorGraph, f::Parfactor, prv::PRV)::Bool
	return rem_edge!(pfg, prv, f)
end

"""
	Base.show(io::IO, pfg::ParfactorGraph)

Show the parfactor graph `pfg` in the given output stream `io`.
"""
function Base.show(io::IO, pfg::ParfactorGraph)
	println(io, "ParfactorGraph:")
	println(io, "\tPRVs: $(prvs(pfg))")
	println(io, "\tParfactors: $(parfactors(pfg))")
	pad_size = 12
	for f in parfactors(pfg)
		println(io, "\t\tPotentials for parfactor $(name(f)):")
		if isempty(f.potentials)
			println(io, "\t\tMissing")
			continue
		end
		h = string("\t\t| ", join(map(x -> lpad(string(x), pad_size), prvs(f)), " | "))
		h = string(h, " | ", lpad(name(f), pad_size), " |")
		println(io, h)
		println(io, string("\t\t|", repeat("-", length(h) - 4), "|"))
		for c in sort(collect(keys(f.potentials)), rev=true)
			p = f.potentials[c]
			print(io, string("\t\t| ", join(map(x -> lpad(x, pad_size), split(c, ",")), " | ")))
			print(io, string(" | ",lpad(p, pad_size), " |", "\n"))
		end
		print(io, "\n")
	end
	print(io, "\tEdges: ")
	for i in eachindex(prvs(pfg))
		prv = prvs(pfg)[i]
		sep = i == length(prvs(pfg)) ? "" : ", "
		print(io, string(
			join(map(x -> string(prv, " - ", x), pfg.prv_edges[prv]), ", "),
			sep
		))
	end
end