@isdefined(LogVar) || include(string(@__DIR__, "/logvars.jl"))

"""
	PRV

Struct to represent a parameterized random variable.
"""
mutable struct PRV
	name::AbstractString
	range::Vector
	logvars::Vector{LogVar}
	counted_over::Union{LogVar, Nothing}
	counted_in::Vector
	PRV(name::AbstractString, range::Vector) =
		new(name, range, [], nothing, [])
	PRV(name::AbstractString, range::Vector, lvs::Vector) =
		new(name, range, lvs, nothing, [])
	PRV(name::AbstractString, range::Vector, lvs::Vector,
		counted_over::Union{LogVar, Nothing}, counted_in::Vector
	) =
		new(name, range, lvs, counted_over, counted_in)
end

"""
	name(prv::PRV)::AbstractString

Return the name of the given parameterized random variable `prv`.
"""
function name(prv::PRV)::AbstractString
	return prv.name
end

"""
	range(prv::PRV)::Vector

Return the range of the given parameterized random variable `prv`.
"""
function range(prv::PRV)::Vector
	return prv.range
end

"""
	logvars(prv::PRV)::Vector{LogVar}

Return the logvars of the given parameterized random variable `prv`.
"""
function logvars(prv::PRV)::Vector{LogVar}
	return prv.logvars
end

"""
	counted_over(prv::PRV)::Union{LogVar, Nothing}

Return the logvar that `prv` is counted over, or `nothing` if it is not
counted over any logvar.
"""
function counted_over(prv::PRV)::Union{LogVar, Nothing}
	return prv.counted_over
end

"""
	counted_in(prv::PRV)::Vector

Return the parfactors in which `prv` appears count converted.
"""
function counted_in(prv::PRV)::Vector
	return prv.counted_in
end

"""
	is_crv(prv::PRV, f)::Bool

Return `true` if the given parameterized random variable `prv` is a
counting random variable in the parfactor f, and `false` otherwise.
"""
function is_crv(prv::PRV, f)::Bool
	return !isnothing(prv.counted_over) && f in counted_in(prv)
end

"""
	Base.deepcopy(prv::PRV)::PRV

Create a deep copy of `prv`.
"""
function Base.deepcopy(prv::PRV)::PRV
	return PRV(
		name(prv),
		deepcopy(range(prv)),
		deepcopy(logvars(prv)),
		deepcopy(counted_over(prv)),
		deepcopy(counted_in(prv))
	)
end

"""
	Base.:(==)(prv1::PRV, prv2::PRV)::Bool

Check whether two parameterized random variables `prv1` and `prv2` are
identical.
"""
function Base.:(==)(prv1::PRV, prv2::PRV)::Bool
	return prv1.name == prv2.name &&
		prv1.range == prv2.range &&
		prv1.logvars == prv2.logvars &&
		prv1.counted_over == prv2.counted_over
		# No counted_in comparison due to circular references
end

"""
	Base.show(io::IO, prv::PRV)

Show the parameterized random variable `prv` in the given output stream `io`.
"""
function Base.show(io::IO, prv::PRV)
	if isempty(logvars(prv)) # Propositional random variable
		print(io, name(prv))
	else
		print(io, string(name(prv), "(", join(logvars(prv), ","), ")"))
	end
end