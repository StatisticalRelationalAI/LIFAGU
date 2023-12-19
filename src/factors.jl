"""
	Factor

Abstract type for factors.
"""
abstract type Factor end

"""
	DiscreteFactor

Struct for discrete factors.

## Examples
```jldoctest
julia> f = DiscreteFactor("f", [DiscreteRV("A")], [([false], 0.5), ([true], 0.5)])
f
```
"""
mutable struct DiscreteFactor <: Factor
	name::String
	rvs::Vector{DiscreteRV}
	potentials::Dict{String, AbstractFloat}
	DiscreteFactor(
		name::String,
		rvs::Vector{DiscreteRV},
		ps::Array # Vector{Tuple{Vector, AbstractFloat}}
	) = new(
		name,
		rvs,
		Dict(join(tuple[1], ",") => tuple[2] for tuple in ps)
	)
end

"""
	name(f::Factor)::String

Return the name of the factor `f`.

## Examples
```jldoctest
julia> f = DiscreteFactor("f", [DiscreteRV("A")], [([false], 0.5), ([true], 0.5)])
f
julia> name(f)
"f"
```
"""
function name(f::Factor)::String
	return f.name
end

"""
	rvs(f::Factor)::Vector{RandVar}

Return all random variables participating in the given factor `f`.

## Examples
```jldoctest
julia> f = DiscreteFactor("f", [DiscreteRV("A")], [([false], 0.5), ([true], 0.5)])
f
julia> rvs(f)
1-element Vector{RandVar}:
 A
```
"""
function rvs(f::Factor)::Vector{RandVar}
	return f.rvs
end

"""
	rvs(f::DiscreteFactor)::Vector{DiscreteRV}

Return all random variables participating in the given factor `f`.

## Examples
```jldoctest
julia> f = DiscreteFactor("f", [DiscreteRV("A")], [([false], 0.5), ([true], 0.5)])
f
julia> rvs(f)
1-element Vector{DiscreteRV}:
 A
```
"""
function rvs(f::DiscreteFactor)::Vector{DiscreteRV}
	return f.rvs
end

"""
	rvpos(f::DiscreteFactor, rv::DiscreteRV)::Int

Return the position of random variable `rv` in factor `f`.

## Examples
```jldoctest
julia> a = DiscreteRV("A")
A
julia> f = DiscreteFactor("f", [a], [([false], 0.5), ([true], 0.5)])
f
julia> rvpos(f, a)
1
```
"""
function rvpos(f::DiscreteFactor, rv::DiscreteRV)::Int
	@assert rv in rvs(f)
	return findfirst(x -> x == rv, rvs(f))
end

"""
	potentials(f::Factor)::Vector{AbstractFloat}

Return the potentials of the given factor `f`.

## Examples
```jldoctest
julia> f = DiscreteFactor("f", [DiscreteRV("A")], [([false], 0.5), ([true], 0.5)])
f
julia> potentials(f)
2-element Vector{Tuple{Vector{SubString{String}}, Float64}}:
 (["true"], 0.5)
 (["false"], 0.5)
```
"""
function potentials(f::Factor)::Array
	return [(split(c, ","), p) for (c, p) in f.potentials]
end

"""
	potential(f::Factor, conf::Vector)::AbstractFloat

Return the potential of the factor `f` with the evidence (configuration)
`conf`.

## Examples
```jldoctest
julia> f = DiscreteFactor("f", [DiscreteRV("A")], [([false], 0.2), ([true], 0.8)])
f
julia> potential(f, [true])
0.8
```
"""
function potential(f::Factor, conf::Vector)::AbstractFloat
	return get(f.potentials, join(conf, ","), NaN)
end

"""
	is_unknown(f::Factor)::Bool

Check whether the factor `f` is unknown.

## Examples
```jldoctest
julia> f = DiscreteFactor("f", [DiscreteRV("A")], [([false], 0.2), ([true], 0.8)])
f
julia> is_unknown(f)
false
julia> f2 = DiscreteFactor("f2", [DiscreteRV("A")], [])
f2
julia> is_unknown(f2)
true
```
"""
function is_unknown(f::Factor)::Bool
	return isempty(potentials(f))
end

"""
	is_valid(f::Factor)::Bool

Check whether the factor `f` is valid (i.e., all potentials are specified).

## Examples
```jldoctest
julia> f = DiscreteFactor("f", [DiscreteRV("A")], [([false], 0.2), ([true], 0.8)])
f
julia> is_valid(f)
true
julia> f2 = DiscreteFactor("f2", [DiscreteRV("A")], [])
f2
julia> is_valid(f2)
false
```
"""
function is_valid(f::Factor)::Bool
	for c in collect(Base.Iterators.product(map(x -> range(x), f.rvs)...))
		isnan(potential(f, [i for i in c])) && return false
	end
	return true
end

"""
	Base.deepcopy(f::Factor)::Factor

Create a deep copy of `f`.
"""
function Base.deepcopy(f::Factor)::Factor
	return DiscreteFactor(name(f), deepcopy(rvs(f)), deepcopy(potentials(f)))
end

"""
	Base.:(==)(f1::Factor, f2::Factor)::Bool

Check whether two factors `f1` and `f2` are identical.
"""
function Base.:(==)(f1::Factor, f2::Factor)::Bool
	return f1.name == f2.name && f1.rvs == f2.rvs &&
		f1.potentials == f2.potentials
end

"""
	Base.show(io::IO, f::Factor)

Show the factor `f` in the given output stream `io`.
"""
function Base.show(io::IO, f::Factor)
	print(io, name(f))
end