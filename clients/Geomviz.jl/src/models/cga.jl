"""
# Conformal geometric algebra

Module containing recipes for 2d-up conformal geometric algebra.

The algebra `CGA{Sig}` is an extension of the base space `Sig` with two additional dimensions,
`vp^2 = +1` and `vm^2 = -1`. Points in the base space `p::Multivector{Sig,a}` are associated to
null vectors in the higher space by
```julia
up(x) = o + x + x^2/2*oo
```
where `o = origin(CGA{Sig})` is the null vector representing the origin and `oo = origin(CGA{Sig})`
represents the point at infinity.

Conformal geometric algebra has covariant representations of points, point-pairs, lines, circles, spheres, and other geometric primitives.
"""
module Conformal

using StyledStrings

using GeometricAlgebra
import ..Geomviz: Rig, encode, dn, normalize, ipns, opns

export CGA
export nullbasis, origin, infinity

export translate

export standardform
export CGABlade, DirectionBlade, FlatBlade, DualFlatBlade, RoundBlade


"""
Metric signature for the conformal geometric algebra over a base space with metric signature ``Sig``.
The conformalised algebra has dimension `dimension(Sig) + 2`, with the two extra basis vectors squaring
to ``+1`` and ``-1``, respectively.
"""
abstract type CGA{Sig} end

GeometricAlgebra.dimension(::Type{CGA{Sig}}) where Sig = dimension(Sig) + 2
function GeometricAlgebra.basis_vector_square(P::Type{CGA{Sig}}, i::Integer) where Sig
	(GeometricAlgebra.canonical_signature(Sig)..., +1, -1)[i]
end


# Sig/CGA{Sig} interoperability

# for fn in [
# 	:(GeometricAlgebra.wedge),
# 	:(GeometricAlgebra.geometric_prod),
# 	:(GeometricAlgebra.sandwich_prod),
# 	:(Base.:+)]
# 	@eval $fn(a::AbstractMultivector{CGA{Sig}}, b::AbstractMultivector{Sig}) where Sig = $fn(a, embed(b))
# 	@eval $fn(a::AbstractMultivector{Sig}, b::AbstractMultivector{CGA{Sig}}) where Sig = $fn(embed(a), b)
# end
# GeometricAlgebra.graded_prod(fn, a::AbstractMultivector{CGA{Sig}}, b::AbstractMultivector{Sig}) where Sig = GeometricAlgebra.graded_prod(fn, a, embed(b))
# GeometricAlgebra.graded_prod(fn, a::AbstractMultivector{Sig}, b::AbstractMultivector{CGA{Sig}}) where Sig = GeometricAlgebra.graded_prod(fn, embed(a), b)

GeometricAlgebra.signature_promote_rule(::Val{CGA{Sig}}, ::Val{Sig}) where Sig = CGA{Sig}
GeometricAlgebra.signature_convert(::Val{CGA{Sig}}, a::AbstractMultivector{Sig}) where Sig = embed(a)

nullbasis(S::Type{CGA{Sig}}) where Sig = (origin = origin(S), infinity = infinity(S))
origin(::Type{CGA{n}}) where n = Multivector{CGA{n},1}([zeros(n); -0.5; 0.5])
infinity(::Type{CGA{n}}) where n = Multivector{CGA{n},1}([zeros(n); +1; +1])

origin(n::Integer) = origin(CGA{n})
infinity(n::Integer) = infinity(CGA{n})
nullbasis(n::Integer) = nullbasis(CGA{n})

"""
	nullbasis(CGA{n}) -> (origin, infinity)
	origin(CGA{n})
	infinity(CGA{n})

Null basis vectors for conformal geometric algebra.

The point at the origin `e₀` and the point at infinity `e∞` in the `n`-dimensional
conformal geometric algebra model, using the convention
``e₀ = (e₊ + e₋)/2`` and ``e∞ = e₋ - e₊``.
"""
origin, infinity, nullbasis



embed(x::AbstractMultivector{Sig}) where {Sig} = GeometricAlgebra.embed(CGA{Sig}, x)
embed(x::AbstractMultivector{CGA{Sig}}) where {Sig} = x
unembed(x::AbstractMultivector{CGA{Sig}}) where {Sig} = GeometricAlgebra.embed(Sig, x)
"""
	embed(::Multivector{Sig,K})::Multivector{CGA{Sig},K}
	unembed(::Multivector{CGA{Sig},K})::Multivector{Sig,K}

Embed a multivector in the algebra `Sig` into the 2d-up conformal algebra `CGA{Sig}`
by setting new components to zero, or "unembed" a 2d-up multivector by discarding extra components.

For any multivector `A` we have `unembed(embed(A)) == A` and `embed∘unembed` is idempotent.
"""
embed, unembed


function up(x::Multivector{Sig,1}) where Sig
	o, oo = origin(Sig), infinity(Sig)
	o + embed(x) + 2\abs2(x)*oo
end
up(x::BasisBlade) = up(Multivector(x))
up(comps::AbstractVector) = up(Multivector{length(comps),1}(comps))

"""
	up(comps...)

Shorthand for `up(Multivector{n,1}(comps))` where `n = length(comps)`.
"""
up(comps...) = up(Multivector{length(comps),1}(comps...))

function normalize(X::Multivector{<:CGA,1})
	o, oo = origin(signature(X)), infinity(signature(X))
	X/-(oo⊙X)
end

basecomps(a::Multivector{CGA{n},1}) where n = a.comps[1:n]

dn(x::Multivector{CGA{n},1}) where n = Multivector{n,1}(basecomps(normalize(x)))


"""
	up(::Multivector{Sig,1})::Multivector{CGA{Sig},1}
	dn(::Multivector{CGA{Sig},1})::Multivector{Sig,1}

"Lift up" a 1-vector in a base space `Sig` to a null vector in the 2d-up conformal algebra `CGA{Sig}`,
or "project down" a conformal 1-vector back into the base space.

The `up` map is given by
```math
up(x) = o + embed(x) + 1/2 x^2 oo
```
where `o = origin(CGA{Sig})` and `oo = infinity(CGA{Sig})` are the points representing the origin and infinity.

For any vector `u` we have `dn(up(u)) == n` and `up∘dn` is idempotent.
"""
up, dn




#= versors =#

function translate(p::Grade{1,CGA{Sig}}) where Sig
	oo = infinity(CGA{Sig})
	1 + 2\oo∧p
end

translate(p::Grade{1,Sig}) where Sig = translate(embed(p))
translate(p, X) = sandwich_prod(translate(p), X)


#= blade standardisation =#

"""
	CGAOBlade{Sig,K} >:
		DirectionBlade{Sig,K}(E)
		FlatBlade{Sig,K}(E, p)
		DualFlatBlade{Sig,K}(E, p)
		RoundBlade{Sig,K}(E, p, r2)

A blade in the conformal geometric algebra `CGA{Sig}` over base space `Sig`.

| Type | Mathematical form |
|:-----|:-----|
| `DirectionBlade(E)` | ``E ∧ ∞`` |
| `FlatBlade(E, p)` | ``Tₚ[𝒪 ∧ E ∧ ∞]`` |
| `DualFlatBlade(E, p)` | ``Tₚ[E]`` |
| `RoundBlade(E, p, r2)` | ``Tₚ[(𝒪 + r2/2 ∞) ∧ E]`` |

Any blade in `CGA{Sig}` is of exactly one of the forms above, where:
- ``E`` is a `K`-blade in the base space
- ``p`` is a position vector in the base space
- ``r2`` is a radius squared, which may be positive or negative
- ``𝒪`` and ``∞`` are the points at the origin and at infinity
- ``Tₚ`` is the translation operator sending ``𝒪`` to ``p``

The method [`standardform`](@ref) classifies any blade in `CGA{Sig}` to one of these forms.

See table 14.1 of [^1] for mathematical details.

[^1]: Dorst, L., Fontijne, D., & Mann, S. (2010). Geometric Algebra for Computer Science: An Object-Oriented Approach to Geometry. Elsevier.
"""
abstract type CGABlade{Sig,K} end

struct DirectionBlade{Sig,K} <: CGABlade{Sig,K}
	E::Multivector{Sig,K}
end
struct FlatBlade{Sig,K} <: CGABlade{Sig,K}
	E::Multivector{Sig,K}
	p::Multivector{Sig,1}
end
struct DualFlatBlade{Sig,K} <: CGABlade{Sig,K}
	E::Multivector{Sig,K}
	p::Multivector{Sig,1}
end
struct RoundBlade{Sig,K} <: CGABlade{Sig,K}
	E::Multivector{Sig,K}
	p::Multivector{Sig,1}
	r2::Float64
end

@doc (@doc CGABlade) (DirectionBlade, FlatBlade, DualFlatBlade, RoundBlade)


GeometricAlgebra.Multivector(X::DirectionBlade{Sig}) where Sig = X.E ∧ infinity(Sig)
GeometricAlgebra.Multivector(X::FlatBlade{Sig}) where Sig = translate(X.p, origin(Sig) ∧ X.E ∧ infinity(Sig))
GeometricAlgebra.Multivector(X::DualFlatBlade{Sig}) where Sig = translate(X.p, X.E)
GeometricAlgebra.Multivector(X::RoundBlade{Sig}) where Sig = translate(X.p, (origin(Sig) + 2\X.r2*infinity(Sig)) ∧ X.E)

function standardform(X::AbstractMultivector{<:CGA})
	o = origin(signature(X))
	oo = infinity(signature(X))

	iszeroish(X) = isapprox(X, 0, atol=sqrt(eps(float(eltype(X)))))

	if iszeroish(X ∧ oo)
		if X ⨽ oo ≈ 0
			E = -unembed(X⨽o)
			DirectionBlade(E)
		else
			Xo = X⨽o # equal to -(o + p)∧E
			p = dn(X⨽Xo) # project origin onto X
			E = unembed(oo⨼Xo)
			FlatBlade(E, p)
		end
	else
		if iszeroish(X ⨽ oo)
			E = unembed(-(X ∧ oo)⨽o)
			if isscalar(E)
				DualFlatBlade(E, dn(o))
			else
				p = -E⨽unembed(X⨽o)/abs2(E)
				DualFlatBlade(E, p)
			end
		else
			p = dn(sandwich_prod(X, oo))
			E = -involution(unembed(X ⨽ oo))
			r2 = (X⊙involution(X))/(E⊙E)
			RoundBlade(E, p, r2)
		end
	end
end






abstract type CGAGeometry{Sig} end
struct PointAtInfinity{Sig} <: CGAGeometry{Sig} end
struct EmptySet{Sig} <: CGAGeometry{Sig} end
struct FlatGeometry{K,Sig} <: CGAGeometry{Sig}
	p::Multivector{Sig,1}
	E::Multivector{Sig,K}
end
struct RoundGeometry{K,Sig} <: CGAGeometry{Sig}
	p::Multivector{Sig,1}
	E::Multivector{Sig,K}
	r2::Float64
end


const Point = RoundGeometry{0,3}
const PointPair = RoundGeometry{1,3}
const Circle = RoundGeometry{2,3}
const Sphere = RoundGeometry{3,3}

const PointFlat = FlatGeometry{0,3}
const Line = FlatGeometry{1,3}
const Plane = FlatGeometry{2,3}



ipns(X::DirectionBlade{Sig}) where Sig = PointAtInfinity{Sig}()
ipns(X::DualFlatBlade) = FlatGeometry(X.p, hodgedual(X.E))
ipns(X::FlatBlade{Sig}) where Sig = EmptySet{Sig}()
ipns(X::RoundBlade) = RoundGeometry(X.p, hodgedual(X.E), -X.r2)

opns(X::DirectionBlade{Sig}) where Sig = PointAtInfinity{Sig}()
opns(X::DualFlatBlade{Sig}) where Sig = EmptySet{Sig}()
opns(X::FlatBlade) = FlatGeometry(X.p, X.E)
opns(X::RoundBlade) = RoundGeometry(X.p, X.E, X.r2)

ipns(X::AbstractMultivector) = ipns(standardform(X))
opns(X::AbstractMultivector) = opns(standardform(X))

"""
	ipns(A)
	opns(A)

Inner or outer product null space of the blade `A`.

This is the set of points `x ∈ ℝⁿ` satisfying `up(x)⋅A ≈ 0` (IPNS) or `up(x)∧A ≈ 0` (OPNS).

Returns a `CGAObject` or `nothing` if the set is empty.
"""
ipns, opns


#= encoding =#


signsqrt(x) = sign(x)sqrt(abs(x))

function encode(X::Union{Point,Sphere})
	if abs(X.r2) < 1e-3
		Rig("Point", location=X.p)
	else
		Rig("Sphere",
			location=X.p,
			"Radius"=>signsqrt(X.r2),
			"Holes"=>X.r2 < 0,
		)
	end
end

function encode(X::PointFlat)
	Rig("Point", location=X.p)
end

encode(X::PointPair) = Rig("Point Pair",
	location=X.p,
	"Direction"=>X.E,
	"Radius"=>signsqrt(X.r2),
)


encode(X::Circle) = Rig("Circle",
	location=X.p,
	"Radius"=>signsqrt(X.r2),
	"Normal"=>rdual(X.E),
)

encode(X::Line) = Rig("Line",
	location=X.p,
	"Direction"=>X.E,
)

encode(X::Plane) = Rig("Plane",
	location=X.p,
	"Normal"=>rdual(X.E),
)

encode(X::AbstractMultivector{<:CGA}) = encode(standardform(X))




#= display methods =#

function showfields(io::IO, X::T) where T
	iszero(nfields(X)) && return
	pad = maximum(length.(string.(fieldnames(T))))
	for field in fieldnames(T)
		printstyled(io, "\n  ", rpad(field, pad), color=:cyan)
		print(io, " = ")
		val = getfield(X, field)
		if val isa Multivector
			GeometricAlgebra.show_multivector(io, val, inline=true, showzeros=false)
		else
			show(io, val)
		end
	end
end

showformula(::Type{<:DirectionBlade}) = "E∧oo"
showformula(::Type{<:FlatBlade}) = "translate(p, o∧E∧oo)"
showformula(::Type{<:DualFlatBlade}) = "translate(p, E)"
showformula(::Type{<:RoundBlade}) = "translate(p, (o + r2/2*oo)∧E)"
function Base.show(io::IO, mime::MIME"text/plain", X::T) where T <: CGABlade{Sig,K} where {Sig,K}
	print(io, T, " of the form ")
	printstyled(io, showformula(T), color=:cyan)
	print(io, ":")
	showfields(io, X)
end

showformula(::Type{<:PointAtInfinity}) = ""
showformula(::Type{<:EmptySet}) = ""
showformula(::Type{<:FlatGeometry}) = styled"through {cyan:p} with direction {cyan:E}"
showformula(::Type{<:RoundGeometry}) = styled"around center {cyan:p} with square radius {cyan:r2} and span {cyan:E}"
function Base.show(io::IO, mime::MIME"text/plain", X::T) where T <: CGAGeometry
	iszero(nfields(X)) && return print(io, T, "()")
	print(io, T, " ", showformula(T), ":")
	showfields(io, X)
end




end