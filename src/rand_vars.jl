"""
	RandVar

Abstract type for random variables.
"""
abstract type RandVar end

"""
	DiscreteRV

Struct for discrete random variables.

## Examples
```jldoctest
julia> rv = DiscreteRV("A")
DiscreteRV("A", Bool[1, 0], -1)
julia> rv2 = DiscreteRV("B", ["low", "medium", "high"])
DiscreteRV("B", ["low", "medium", "high"], -1)
julia> rv3 = DiscreteRV("C", ["low", "medium", "high"], "high")
DiscreteRV("C", ["low", "medium", "high"], 3)
```
"""
mutable struct DiscreteRV <: RandVar
	name::AbstractString
	range::Vector
	evidence::Int
	DiscreteRV(n::AbstractString, r::Vector, ev::Any) = begin
		rv = new(n, r, -1)
		set_evidence!(rv, ev)
		return rv
	end
	DiscreteRV(n::AbstractString, r::Vector) = DiscreteRV(n, r, -1)
	DiscreteRV(n::AbstractString) = DiscreteRV(n, [true, false], -1)
end

"""
	name(rv::RandVar)::String

Return the name of the random variable `rv`.

## Examples
```jldoctest
julia> rv = DiscreteRV("A")
DiscreteRV("A", Bool[1, 0], -1)
julia> name(rv)
"A"
```
"""
function name(rv::RandVar)::String
	return rv.name
end

"""
	range(rv::RandVar)::Vector

Return the range of the random variable `rv`.

## Examples
```jldoctest
julia> rv = DiscreteRV("A", ["low", "medium", "high"])
DiscreteRV("A", ["low", "medium", "high"], -1)
julia> range(rv)
3-element Vector{String}:
 "low"
 "medium"
 "high"
```
"""
function range(rv::RandVar)::Vector
	return rv.range
end

"""
	evidence(rv::RandVar)::Any

Return the evidence of the random variable `rv`.
If no evidence is set, "None" is returned.

## Examples
```jldoctest
julia> rv = DiscreteRV("A", ["low", "medium", "high"], "medium")
DiscreteRV("A", ["low", "medium", "high"], 2)
julia> evidence(rv)
"medium"
julia> rv2 = DiscreteRV("B", ["low", "medium", "high"])
DiscreteRV("B", ["low", "medium", "high"], -1)
julia> evidence(rv2)
"None"
```
"""
function evidence(rv::RandVar)::Any
	return rv.evidence == -1 ? "None" : rv.range[rv.evidence]
end

"""
	set_evidence!(rv::RandVar, val::Any)::Bool

Set the evidence of the random variable `rv` to `val`.
Return `true` on success, else `false`.

## Examples
```jldoctest
julia> rv = DiscreteRV("A", ["low", "medium", "high"], "medium")
DiscreteRV("A", ["low", "medium", "high"], 2)
julia> evidence(rv)
"medium"
julia> set_evidence!(rv, "low")
true
julia> evidence(rv)
"low"
julia> set_evidence!(rv, "bla")
false
julia> evidence(rv)
"low"
```
"""
function set_evidence!(rv::RandVar, val::Any)::Bool
	idx = findfirst(v -> v == val, rv.range)
	if !isnothing(idx)
		rv.evidence = idx
		return true
	end
	return false
end

"""
	Base.deepcopy(rv::RandVar)::RandVar

Create a deep copy of `rv`.
"""
function Base.deepcopy(rv::RandVar)::RandVar
	return DiscreteRV(name(rv), deepcopy(range(rv)), evidence(rv))
end

"""
	Base.:(==)(rv1::RandVar, rv2::RandVar)::Bool

Check whether two random variables `rv1` and `rv2` are identical.
"""
function Base.:(==)(rv1::RandVar, rv2::RandVar)::Bool
	return rv1.name == rv2.name && rv1.range == rv2.range &&
		rv1.evidence == rv2.evidence
end

"""
	Base.show(io::IO, rv::RandVar)

Show the random variable `rv` in the given output stream `io`.
"""
function Base.show(io::IO, rv::RandVar)
	print(io, name(rv))
end