@isdefined(RandVar) || include(string(@__DIR__, "/rand_vars.jl"))
@isdefined(Factor)  || include(string(@__DIR__, "/factors.jl"))

"""
	FactorGraph

Struct for factor graphs.

## Examples
```jldoctest
julia> fg = FactorGraph()
FactorGraph:
        RVs: String[]
        Factors: String[]
        Edges:
```
"""
struct FactorGraph
	rvs::Vector{RandVar}
	rv_edges::Dict{RandVar, Vector{Factor}}
	factors::Vector{Factor}
	factor_edges::Dict{Factor, Vector{RandVar}}
	FactorGraph() = new([], Dict(), [], Dict())
end

"""
	rvs(fg::FactorGraph)::Vector{RandVar}

Return all random variables in the given factor graph `fg`.

## Examples
```jldoctest
julia> fg = FactorGraph()
FactorGraph:
        RVs: String[]
        Factors: String[]
        Edges:
julia> rvs(fg)
RandVar[]
julia> add_rv!(fg, DiscreteRV("A"))
true
julia> rvs(fg)
1-element Vector{RandVar}:
 A
```
"""
function rvs(fg::FactorGraph)::Vector{RandVar}
	return fg.rvs
end

"""
	factors(fg::FactorGraph)::Vector{Factor}

Return all factors in the given factor graph `fg`.

## Examples
```jldoctest
julia> fg = FactorGraph()
FactorGraph:
        RVs: String[]
        Factors: String[]
        Edges:
julia> factors(fg)
Factor[]
julia> add_factor!(fg, DiscreteFactor("f", [DiscreteRV("A")], [[false, 0.5], [true, 0.5]]))
true
julia> factors(fg)
1-element Vector{Factor}:
 f
```
"""
function factors(fg::FactorGraph)::Vector{Factor}
	return fg.factors
end

"""
	numrvs(fg::FactorGraph)::Int

Return the number of random variables in the factor graph `fg`.

## Examples
```jldoctest
julia> fg = FactorGraph();
julia> numrvs(fg)
0
```
"""
function numrvs(fg::FactorGraph)::Int
	return length(fg.rvs)
end

"""
	numfactors(fg::FactorGraph)::Int

Return the number of factors in the factor graph `fg`.

## Examples
```jldoctest
julia> fg = FactorGraph();
julia> numfactors(fg)
0
```
"""
function numfactors(fg::FactorGraph)::Int
	return length(fg.factors)
end

"""
	numnodes(fg::FactorGraph)::Int

Return the number of nodes (random variables and factors)
in the factor graph `fg`.

## Examples
```jldoctest
julia> fg = FactorGraph();
julia> numnodes(fg)
0
```
"""
function numnodes(fg::FactorGraph)::Int
	return length(fg.rvs) + length(fg.factors)
end

"""
	contains_rv(fg::FactorGraph, rv::RandVar)::Bool

Check whether the factor graph `fg` contains the random variable `rv`.

## Examples
```julia-repl
julia> fg = FactorGraph()
FactorGraph:
        RVs: String[]
        Factors: String[]
        Edges:
julia> a = DiscreteRV("A")
A
julia> add_rv!(fg, a)
true
julia> contains_rv(fg, a)
true
```
"""
function contains_rv(fg::FactorGraph, rv::RandVar)::Bool
	return any(x -> x == rv, fg.rvs)
end

"""
	contains_factor(fg::FactorGraph, f::Factor)::Bool

Check whether the factor graph `fg` contains the factor `f`.

## Examples
```julia-repl
julia> fg = FactorGraph()
FactorGraph:
        RVs: String[]
        Factors: String[]
        Edges:
julia> f = DiscreteFactor("f", [DiscreteRV("A")], [[false, 0.5], [true, 0.5]])
f
julia> add_factor!(fg, f)
true
julia> contains_factor(fg, f)
true
```
"""
function contains_factor(fg::FactorGraph, f::Factor)::Bool
	return any(x -> x == f, fg.factors)
end

"""
	edges(fg::FactorGraph, rv::RandVar)::Vector{Factor}

Return all factors in the given factor graph `fg` that are connected
to the random variable `rv` via an edge.

## Examples
```jldoctest
julia> fg = FactorGraph()
FactorGraph:
        RVs: String[]
        Factors: String[]
        Edges:
julia> a = DiscreteRV("A")
A
julia> add_rv!(fg, a)
true
julia> f = DiscreteFactor("f", [a], [[false, 0.5], [true, 0.5]])
f
julia> add_factor!(fg, f)
true
julia> add_edge!(fg, a, f)
true
julia> edges(fg, a)
1-element Vector{Factor}:
 f
```
"""
function edges(fg::FactorGraph, rv::RandVar)::Vector{Factor}
	return get(fg.rv_edges, rv, [])
end

"""
	edges(fg::FactorGraph, f::Factor)::Vector{RandVar}

Return all random variables in the given factor graph `fg` that are
connected to the factor `f` via an edge.

## Examples
```jldoctest
julia> fg = FactorGraph()
FactorGraph:
        RVs: String[]
        Factors: String[]
        Edges:
julia> a = DiscreteRV("A")
A
julia> add_rv!(fg, a)
true
julia> f = DiscreteFactor("f", [a], [[false, 0.5], [true, 0.5]])
f
julia> add_factor!(fg, f)
true
julia> add_edge!(fg, a, f)
true
julia> edges(fg, f)
1-element Vector{RandVar}:
 A
```
"""
function edges(fg::FactorGraph, f::Factor)::Vector{RandVar}
	return get(fg.factor_edges, f, [])
end

"""
	add_rv!(fg::FactorGraph, rv::RandVar)::Bool

Add the random variable `rv` to the factor graph `fg`.
Return `true` on success, else `false`.

## Examples
```jldoctest
julia> fg = FactorGraph()
FactorGraph:
        RVs: String[]
        Factors: String[]
        Edges:
julia> add_rv!(fg, DiscreteRV("A"))
true
```
"""
function add_rv!(fg::FactorGraph, rv::RandVar)::Bool
	if !contains_rv(fg, rv)
		push!(fg.rvs, rv)
		fg.rv_edges[rv] = []
		return true
	end
	return false
end

"""
	rem_rv!(fg::FactorGraph, rv::RandVar)::Bool

Remove the random variable `rv` from the factor graph `fg`.
Return `true` on success, else `false`.

## Examples
```jldoctest
julia> fg = FactorGraph()
FactorGraph:
        RVs: String[]
        Factors: String[]
        Edges:
julia> a = DiscreteRV("A")
A		
julia> add_rv!(fg, a)
true
julia> rvs(fg)
1-element Vector{RandVar}:
 A
julia> rem_rv!(fg, a)
true
julia> rvs(fg)
RandVar[]
```
"""
function rem_rv!(fg::FactorGraph, rv::RandVar)::Bool
	if contains_rv(fg, rv)
		deleteat!(fg.rvs, findall(x -> x == rv, fg.rvs))
		return true
	end
	return false
end

"""
	add_factor!(fg::FactorGraph, f::Factor)::Bool

Add the factor `f` to the factor graph `fg`.
Return `true` on success, else `false`.

## Examples
```jldoctest
julia> fg = FactorGraph()
FactorGraph:
        RVs: String[]
        Factors: String[]
        Edges:
julia> add_factor!(fg, DiscreteFactor("f", [DiscreteRV("A")], [[false, 0.5], [true, 0.5]]))
true
```
"""
function add_factor!(fg::FactorGraph, f::Factor)::Bool
	if !contains_factor(fg, f)
		push!(fg.factors, f)
		fg.factor_edges[f] = []
		return true
	end
	return false
end

"""
	rem_factor!(fg::FactorGraph, f::Factor)::Bool

Remove the factor `f` from the factor graph `fg`.
Return `true` on success, else `false`.

## Examples
```jldoctest
julia> fg = FactorGraph()
FactorGraph:
        RVs: String[]
        Factors: String[]
        Edges:
julia> f = DiscreteFactor("f", [DiscreteRV("A")], [[false, 0.5], [true, 0.5]])
f
julia> add_factor!(fg, f)
true
julia> factors(fg)
1-element Vector{Factor}:
 f
julia> rem_factor!(fg, f)
true
julia> factors(fg)
Factor[]
```
"""
function rem_factor!(fg::FactorGraph, f::Factor)::Bool
	if contains_factor(fg, f)
		deleteat!(fg.factors, findall(x -> x == f, fg.factors))
		return true
	end
	return false
end

"""
	has_edge(fg::FactorGraph, rv::RandVar, f::Factor)::Bool

Check whether the factor graph `fg` contains an edge between the random
variable `rv` and the factor `f`.

## Examples
```jldoctest
julia> fg = FactorGraph()
FactorGraph:
        RVs: String[]
        Factors: String[]
        Edges:
julia> a = DiscreteRV("A")
A
julia> f = DiscreteFactor("f", [a], [[false, 0.5], [true, 0.5]])
f
julia> has_edge(fg, a, f)
false
julia> add_edge!(fg, a, f)
true
julia> has_edge(fg, a, f)
true
```
"""
function has_edge(fg::FactorGraph, rv::RandVar, f::Factor)::Bool
	return f in edges(fg, rv) && rv in edges(fg, f)
end

"""
	has_edge(fg::FactorGraph, f::Factor, rv::RandVar)::Bool

Check whether the factor graph `fg` contains an edge between the random
variable `rv` and the factor `f`.

## Examples
```jldoctest
julia> fg = FactorGraph()
FactorGraph:
        RVs: String[]
        Factors: String[]
        Edges:
julia> a = DiscreteRV("A")
A
julia> f = DiscreteFactor("f", [a], [[false, 0.5], [true, 0.5]])
f
julia> has_edge(fg, f, a)
false
julia> add_edge!(fg, f, a)
true
julia> has_edge(fg, f, a)
true
```
"""
function has_edge(fg::FactorGraph, f::Factor, rv::RandVar)::Bool
	return has_edge(fg, rv, f)
end

"""
	add_edge!(fg::FactorGraph, rv::RandVar, f::Factor)::Bool

Add an edge between the random variable `rv` and the factor `f` to the
factor graph `fg`.
Return `true` on success, else `false`.

## Examples
```jldoctest
julia> fg = FactorGraph()
FactorGraph:
        RVs: String[]
        Factors: String[]
        Edges:
julia> a = DiscreteRV("A")
A
julia> f = DiscreteFactor("f", [a], [[false, 0.5], [true, 0.5]])
f
julia> add_edge!(fg, a, f)
true
```
"""
function add_edge!(fg::FactorGraph, rv::RandVar, f::Factor)::Bool
	if !has_edge(fg, rv, f)
		push!(fg.rv_edges[rv], f)
		push!(fg.factor_edges[f], rv)
		return true
	end
	return false
end

"""
	add_edge!(fg::FactorGraph, f::Factor, rv::RandVar)::Bool

Add an edge between the random variable `rv` and the factor `f` to the
factor graph `fg`.
Return `true` on success, else `false`.

## Examples
```jldoctest
julia> fg = FactorGraph()
FactorGraph:
        RVs: String[]
        Factors: String[]
        Edges:
julia> a = DiscreteRV("A")
A
julia> f = DiscreteFactor("f", [a], [[false, 0.5], [true, 0.5]])
f
julia> add_edge!(fg, f, a)
true
```
"""
function add_edge!(fg::FactorGraph, f::Factor, rv::RandVar)::Bool
	return add_edge!(fg, rv, f)
end

"""
	rem_edge!(fg::FactorGraph, rv::RandVar, f::Factor)::Bool

Remove the edge between the random variable `rv` and the factor `f` from
the factor graph `fg`.
Return `true` on success, else `false`.

## Examples
```jldoctest
julia> fg = FactorGraph()
FactorGraph:
        RVs: String[]
        Factors: String[]
        Edges:
julia> a = DiscreteRV("A")
A
julia> f = DiscreteFactor("f", [a], [[false, 0.5], [true, 0.5]])
f
julia> add_edge!(fg, a, f)
true
julia> rem_edge!(fg, a, f)
true
```
"""
function rem_edge!(fg::FactorGraph, rv::RandVar, f::Factor)::Bool
	if has_edge(fg, rv, f)
		deleteat!(fg.rv_edges[rv], findfirst(x -> x == f, fg.rv_edges[rv]))
		deleteat!(fg.factor_edges[f], findfirst(x -> x == rv, fg.factor_edges[f]))
		return true
	end
	return false
end

"""
	rem_edge!(fg::FactorGraph, f::Factor, rv::RandVar)::Bool

Remove the edge between the random variable `rv` and the factor `f` from
the factor graph `fg`.
Return `true` on success, else `false`.

## Examples
```jldoctest
julia> fg = FactorGraph()
FactorGraph:
        RVs: String[]
        Factors: String[]
        Edges:
julia> a = DiscreteRV("A")
A
julia> f = DiscreteFactor("f", [a], [[false, 0.5], [true, 0.5]])
f
julia> add_rv!(fg, a)
true
julia> add_factor!(fg, f)
true
julia> add_edge!(fg, f, a)
true
julia> rem_edge!(fg, f, a)
true
```
"""
function rem_edge!(fg::FactorGraph, f::Factor, rv::RandVar)::Bool
	return rem_edge!(fg, rv, f)
end

"""
	unknown_factors(fg::FactorGraph)::Vector{Factor}

Return all unknown (missing) factors in `fg`.

## Examples
```jldoctest
julia> fg = FactorGraph()
FactorGraph:
        RVs: String[]
        Factors: String[]
        Edges:
julia> a = DiscreteRV("A")
A
julia> f = DiscreteFactor("f", [a], [[false, 0.5], [true, 0.5]])
f
julia> add_rv!(fg, a)
true
julia> add_factor!(fg, f)
true
julia> unknown_factors(fg)
1-element Vector{Factor}:
 f
```
"""
function unknown_factors(fg::FactorGraph)::Vector{Factor}
	return [f for f in factors(fg) if is_unknown(f)]
end

"""
	is_valid(fg::FactorGraph)::Bool

Check whether the factor graph `fg` is valid.

## Examples
```jldoctest
julia> fg = FactorGraph()
FactorGraph:
        RVs: String[]
        Factors: String[]
        Edges:
julia> is_valid(fg)
true
julia> a = DiscreteRV("A")
A
julia> add_rv!(fg, a)
true
julia> is_valid(fg)
true
julia> f = DiscreteFactor("f", [a], [[false, 0.5], [true, 0.5]])
f
julia> add_factor!(fg, f)
true
julia> is_valid(fg)
false
julia> add_edge!(fg, a, f)
true
julia> is_valid(fg)
true
```
"""
function is_valid(fg::FactorGraph)::Bool
	for f in factors(fg)
		is_valid(f) || return false
		length(edges(fg, f)) == length(rvs(f)) || return false
		all(x -> has_edge(fg, f, x), rvs(f)) || return false
	end
	return true
end

"""
	reachable(fg::FactorGraph, from::RandVar, to::RandVar)::Bool

Check whether a random variable `to` is reachable from a random variable
`from` in a factor graph `fg`.

## Examples
```jldoctest
julia> fg = FactorGraph();
julia> a = DiscreteRV("A")
A
julia> b = DiscreteRV("B")
B
julia> add_rv!(fg, a)
true
julia> add_rv!(fg, b)
true
julia> reachable(fg, a, b)
false
```
"""
function reachable(fg::FactorGraph, from::RandVar, to::RandVar)::Bool
	from == to && return true

	visited = Set{Union{RandVar, Factor}}()
	queue::Vector{Union{RandVar, Factor}} = [from]
	while !isempty(queue)
		node = pop!(queue)
		push!(visited, node)
		for nbr in edges(fg, node)
			isa(nbr, RandVar) && nbr == to && return true
			!(nbr in visited) && push!(queue, nbr)
		end
	end
	return false
end

"""
	is_connected(fg::FactorGraph)::Bool

Check whether the factor graph `fg` is connected (i.e., every random
variable is connected via a path to any other random variable).

## Examples
```jldoctest
julia> fg = FactorGraph();
julia> a = DiscreteRV("A")
A
julia> b = DiscreteRV("B")
B
julia> add_rv!(fg, a)
true
julia> add_rv!(fg, b)
true
julia> is_connected(fg)
false
```
"""
function is_connected(fg::FactorGraph)::Bool
	for a in rvs(fg), b in rvs(fg)
		reachable(fg, a, b) || return false
	end
	return true
end

"""
	Base.deepcopy(fg::FactorGraph)::FactorGraph

Create a deep copy of `fg`.
"""
function Base.deepcopy(fg::FactorGraph)::FactorGraph
	fg_cpy = FactorGraph()

	for f in factors(fg)
		f_cpy = deepcopy(f)
		add_factor!(fg_cpy, f_cpy)
		for rv_cpy in rvs(f_cpy)
			rv_edge = findfirst(rv -> name(rv) == name(rv_cpy), rvs(fg_cpy))
			if isnothing(rv_edge)
				add_rv!(fg_cpy, rv_cpy)
				add_edge!(fg_cpy, rv_cpy, f_cpy)
			else
				f_cpy_rvs = rvs(f_cpy)
				new_rv = rvs(fg_cpy)[rv_edge]
				f_cpy_rvs[findfirst(rv -> rv == rv_cpy, f_cpy_rvs)] = new_rv
				add_edge!(fg_cpy, new_rv, f_cpy)
			end
		end
	end

	# If there are random variables not connected to any factor,
	# they are added now (without edges, as they are unconnected)
	rv_names = map(rv -> name(rv), rvs(fg_cpy))
	for rv in rvs(fg)
		if !(name(rv) in rv_names)
			add_rv!(fg_cpy, deepcopy(rv))
		end
	end

	return fg_cpy
end

"""
	Base.:(==)(fg1::FactorGraph, fg2::FactorGraph)::Bool

Check whether two factor graphs `fg1` and `fg2` are identical.
"""
function Base.:(==)(fg1::FactorGraph, fg2::FactorGraph)::Bool
	sort(fg1.rvs, by=r->name(r)) == sort(fg2.rvs, by=r->name(r)) || return false
	sort(fg1.factors, by=f->name(f)) == sort(fg2.factors, by=f->name(f)) || return false

	rvk1 = sort(collect(keys(fg1.rv_edges)), by=rv->name(rv))
	rvk2 = sort(collect(keys(fg2.rv_edges)), by=rv->name(rv))
	rvk1 == rvk2 || return false
	for i in eachindex(rvk1)
		e1 = sort(fg1.rv_edges[rvk1[i]], by=f->name(f))
		e2 = sort(fg2.rv_edges[rvk2[i]], by=f->name(f))
		e1 == e2 || return false
	end

	fk1 = sort(collect(keys(fg1.factor_edges)), by=f->name(f))
	fk2 = sort(collect(keys(fg2.factor_edges)), by=f->name(f))
	fk1 == fk2 || return false
	for i in eachindex(fk1)
		e1 = sort(fg1.factor_edges[fk1[i]], by=rv->name(rv))
		e2 = sort(fg2.factor_edges[fk2[i]], by=rv->name(rv))
		e1 == e2 || return false
	end

	return true
end

"""
	Base.show(io::IO, fg::FactorGraph)

Show the factor graph `fg` in the given output stream `io`.
"""
function Base.show(io::IO, fg::FactorGraph)
	println(io, "FactorGraph:")
	println(io, "\tRVs: $(map(x -> name(x), rvs(fg)))")
	println(io, "\tFactors: $(map(x -> name(x), factors(fg)))")
	pad_size = 12
	for f in factors(fg)
		println(io, "\t\tPotentials for factor $(name(f)):")
		if isempty(f.potentials)
			println(io, "\t\tMissing")
			continue
		end
		h = string("\t\t| ", join(map(x -> lpad(name(x), pad_size), rvs(f)), " | "))
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
	for i = 1:length(rvs(fg))
		rv = rvs(fg)[i]
		sep = i == length(rvs(fg)) ? "" : ", "
		print(io, string(
			join(map(x -> string(rv, " - ", x), fg.rv_edges[rv]), ", "),
			sep
		))
	end
end