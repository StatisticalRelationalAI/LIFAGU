"""
	Parfactor

Struct to represent a parfactor.
"""
mutable struct Parfactor
	name::AbstractString
	prvs::Vector{PRV}
	potentials::Dict{String, AbstractFloat}
	Parfactor(
		name::AbstractString,
		prvs::Vector{PRV},
		ps::Array # Vector{Tuple{Vector, AbstractFloat}}
	) = new(
		name,
		prvs,
		Dict(join(tuple[1], ",") => tuple[2] for tuple in ps)
	)
end

"""
	name(f::Parfactor)::AbstractString

Return the name of the parfactor `f`.
"""
function name(f::Parfactor)::AbstractString
	return f.name
end

"""
	prvs(f::Parfactor)::Vector{PRV}

Return the parameterized random variables contained in the parfactor `f`.
"""
function prvs(f::Parfactor)::Vector{PRV}
	return f.prvs
end

"""
	potentials(f::Parfactor)::Array

Return the potentials of the parfactor `f` (in any order).
"""
function potentials(f::Parfactor)::Array
	return [(split(c, ","), p) for (c, p) in f.potentials]
end

"""
	potentials_ordered(f::Parfactor)::Array

Return the potentials of the parfactor `f` (in sorted order, i.e., in order
of descending variable assignments).
"""
function potentials_ordered(f::Parfactor)::Array
	sorted_keys = sort(collect(keys(f.potentials)), rev = true)
	return [f.potentials[key] for key in sorted_keys]
end

"""
	potential(f::Parfactor, conf::Vector)::AbstractFloat

Return the potential of the parfactor `f` for the configuration (variable
assignment) `conf`.
"""
function potential(f::Parfactor, conf::Vector)::AbstractFloat
	return get(f.potentials, join(conf, ","), NaN)
end

"""
	Base.deepcopy(f::Parfactor)::Parfactor

Return a deep copy of the parfactor `f`.
"""
function Base.deepcopy(f::Parfactor)::Parfactor
	return Parfactor(name(f), deepcopy(prvs(f)), deepcopy(potentials(f)))
end

"""
	Base.:(==)(f1::Parfactor, f2::Parfactor)::Bool

Check whether the parfactors `f1` and `f2` are equal.
"""
function Base.:(==)(f1::Parfactor, f2::Parfactor)::Bool
	return f1.name == f2.name &&
		f1.prvs == f2.prvs &&
		f1.potentials == f2.potentials
end

"""
	Base.show(io::IO, f::Parfactor)

Show the parfactor `f` in the given output stream `io`.
"""
function Base.show(io::IO, f::Parfactor)
	print(io, name(f))
end