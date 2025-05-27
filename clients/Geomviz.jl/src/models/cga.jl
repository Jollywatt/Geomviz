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

using GeometricAlgebra
import ..Geomviz: Rig, encode, dn, normalize, classify

export nullbasis, origin, infinity
export classify, ipns, opns
export Flat, PointFlat, Line, Plane
export Round, PointPair, Circle, Sphere
export Tangent, Point
export Direction

export translate
export standardform


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


nullbasis(S::Type{CGA{Sig}}) where Sig = (origin = origin(S), infinity = infinity(S))
origin(::Type{CGA{n}}) where n = Multivector{CGA{n},1}([zeros(n); -0.5; 0.5])
infinity(::Type{CGA{n}}) where n = Multivector{CGA{n},1}([zeros(n); +1; +1])
"""
	nullbasis(CGA{n}) -> (origin, infinity)
	origin(CGA{n})
	infinity(CGA{n})

The point at the origin `e₀` and the point at infinity `e∞` in the `n`-dimensional
conformal geometric algebra model, using the convention
``e₀ = (e₊ + e₋)/2`` and ``e∞ = e₋ - e₊``.
"""
origin, infinity, nullbasis



embed(x::Multivector{Sig}) where {Sig} = GeometricAlgebra.embed(CGA{Sig}, x)
unembed(x::Multivector{CGA{Sig}}) where {Sig} = GeometricAlgebra.embed(Sig, x)
"""
	embed(::Multivector{Sig,K})::Multivector{CGA{Sig},K}
	unembed(::Multivector{CGA{Sig},K})::Multivector{Sig,K}

Embed a multivector in the algebra `Sig` into the 2d-up conformal algebra `CGA{Sig}`
by setting new components to zero, or "unembed" a 2d-up multivector by discarding extra components.

For any multivector `A` we have `unembed(embed(A)) == A` and `embed∘unembed` is idempotent.
"""
embed, unembed


function up(x::Multivector{Sig,1}) where Sig
	o, oo = origin(CGA{Sig}), infinity(CGA{Sig})
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



"""
	CGAObject{D,Sig} >:
		Flat{D,Sig}(location::Grade{1,Sig}, direction::Grade{K,Sig})
		Round{D,Sig}(carrier::Flat{D,Sig}, radius::Float64)
		Tangent{D,Sig}(carrier::Flat{D,Sig})
		Direction{D,Sig}(direction::Grade{D,Sig})

A geometric object described by a blade in conformal geometric algebra.
Any blade in `CGA{Sig}` is of one of the forms represented by these types.

In the list below, ``p, A`` are a position vector and blade in the base space,
``𝒪, ∞`` are the points at the origin and at infinity, 
``Tₚ[X]`` is the translation operator and ``r > 0`` is a radius.

- `Flat{k}(p, A)`: A blade of the form ``Tₚ[𝒪 ∧ A ∧ ∞] = up(p) ∧ A ∧ ∞``,
  representing an affine `k`-plane through ``p`` in the ``A`` direction.

- `Round{k}(Flat(p, A), r)`: A blade of the form ``Tₚ[(𝒪 + r²/2 ∞) ∧ A]``,
  representing a `(k - 1)`-sphere within the affine `k`-plane `Flat(p, A)`
  with center `p` and radius `r`.

- `Tangent(Flat(p, A))`: A blade of the form ``Tₚ[𝒪 ∧ A]``, representing a blade ``A``
  rooted at the point ``p``, equal to the zero-radius round `Round(Flat(p, A), 0)`.
  Tangents describe the base space's _tangent bundle_ of blades.

- `Direction{k}(A)`: A blade of the form ``A ∧ ∞``, representing a pure `k`-dimensional direction.
  Like a `Flat` without a location.

See table 14.1 of [^1] for details.

[^1]: Dorst, L., Fontijne, D., & Mann, S. (2010). Geometric Algebra for Computer Science: An Object-Oriented Approach to Geometry. Elsevier.
"""
abstract type CGAObject{D,Sig} end


struct Flat{D,Sig} <: CGAObject{D,Sig}
	location::Multivector{Sig,1}
	direction::Multivector{Sig,D}
end
struct Round{D,Sig} <: CGAObject{D,Sig}
	carrier::Flat{D,Sig}
	radius::Float64
end
struct Tangent{D,Sig} <: CGAObject{D,Sig}
	carrier::Flat{D,Sig}
end
struct Direction{D,Sig} <: CGAObject{D,Sig}
	direction::Multivector{Sig,D}
end

@doc (@doc CGAObject) (Flat, Round, Tangent, Direction)

location(x::Flat) = x.location
location(x::Union{Round,Tangent}) = location(x.carrier)

direction(x::Flat) = x.direction
direction(x::Union{Round,Tangent}) = direction(x.carrier)

radius(x::Round) = x.radius
radius(x::Tangent)::Float64 = 0


const Point = Tangent{0}

const PointPair = Round{1}
const Circle = Round{2}
const Sphere = Round{3}

const PointFlat = Flat{0}
const Line = Flat{1}
const Plane = Flat{2}

"""
	contains(X::CGAObject{D,Sig}, point::Grade{1,Sig})

Whether the conformal geometric algebra object `X` contains `point`, given as a location vector in the base space.

If `X` is a `Flat{k}` or `Round{k}`, this is true when `point` lies on the `k`-plane or `(k - 1)`-sphere described by `X`.
A `Tangent` contains exactly one point, `location(X)`, and a `Direction` contains no points.
"""
Base.contains(x::Flat{D,Sig}, p::Grade{1,Sig}) where {D,Sig} = isapprox((p - location(x))∧direction(x), 0, atol=eps(eltype(p)))
Base.contains(x::Round{D,Sig}, p::Grade{1,Sig}) where {D,Sig} = contains(x.carrier, p) && abs2(p - location(x)) ≈ abs2(radius(x))
Base.contains(x::Tangent, p::Grade{1,Sig}) where {Sig} = location(x) ≈ p
Base.contains(x::Direction, p) = false

function samplepoint(x::Round{D,Sig}) where {D,Sig}
	@assert D > 0 "$(typeof(x)) contains no points; cannot sample"
	p = randn(Multivector{Sig,D - 1})
	r = p ⨼ direction(x)
	r *= radius(x)/sqrt(abs2(r))
	location(x) + r
end
samplepoint(x::Flat) = samplepoint(Round(x, randn()))

encode(x::Union{Point,PointFlat}) = Rig("Point", location=location(x))

encode(x::PointPair) = Rig("Point Pair",
	location=location(x),
	"Direction"=>direction(x),
	"Radius"=>radius(x)
)

encode(x::Circle) = Rig("Spear Circle",
	location=location(x),
	"Radius"=>radius(x),
	"Normal"=>rdual(direction(x)),
)

encode(x::Union{Sphere,Round{0}}) = Rig("Sphere",
	location=location(x),
	"Radius"=>abs(radius(x)),
	"Holes"=>radius(x) < 0,
)

encode(x::Line) = Rig("Spear Line",
	location=location(x),
	"Direction"=>direction(x),
)

encode(x::Plane) = Rig("Plane",
	location=location(x),
	"Normal"=>rdual(direction(x)),
)

encode(x::Tangent{1}) = Rig("Arrow Vector",
	location=location(x),
	"Vector"=>direction(x),
)

encode(x::Tangent{2}) = Rig("Spear Disk",
	location=location(x),
	"Normal"=>rdual(direction(x)),
)

function opns(x::Multivector{<:CGA})
	o, oo = origin(signature(x)), infinity(signature(x))

	if x ∧ oo ≈ 0 # flats or directions
		if x ⨽ oo ≈ 0 # directions
			dir = unembed(x ⨽ -o)
			Direction(dir)
		else # flats
			loc = dn(x⨽(x⨽o))
			dir = unembed(involution(x)⨽(o∧oo))
			Flat(loc, dir)
		end
	else
		y = x ⨽ oo
		if y ≈ 0
			# empty OPNS
			nothing
		else # rounds
			loc = dn(sandwich_prod(x, oo))
			dir = unembed((involution(x) ⨽ oo))
			ρ² = x⊙x/(y⊙y)
			if abs(ρ²) < sqrt(eps())
				Tangent(Flat(loc, dir))
			else
				ρ = sign(ρ²)sqrt(abs(ρ²))
				Round(Flat(loc, dir), ρ)
			end
		end
	end

end

ipns(x) = opns(hodgedual(x))

"""
	ipns(A)
	opns(A)

Inner or outer product null space of the blade `A`.

This is the set of points `x ∈ ℝⁿ` satisfying `up(x)⋅A ≈ 0` (IPNS) or `up(x)∧A ≈ 0` (OPNS).

Returns a `CGAObject` or `nothing` if the set is empty.
"""
ipns, opns

function classify(x::AbstractMultivector{<:CGA})
	o, oo = origin(signature(x)), infinity(signature(x))

	x² = x*x
	isapprox(x², scalar(x²), atol=sqrt(eps())) || return nothing

	obj = opns(x)
	isnothing(obj) ? ipns(x) : obj

end

encode(x::Multivector{CGA{3}}) = encode(classify(x))




#= versors =#

function translate(p::Grade{1,CGA{Sig}}) where Sig
	oo = infinity(CGA{Sig})
	1 + 2\oo∧p
end

translate(p::Grade{1,Sig}) where Sig = translate(embed(p))
translate(p, X) = sandwich_prod(translate(p), X)


abstract type CGABlade{Sig,T} end

struct DirectionBlade{Sig,K} <: CGABlade{Sig,K}
	E::Multivector{Sig,K}
end
struct FlatBlade{Sig,K} <: CGABlade{Sig,K}
	p::Multivector{Sig,1}
	E::Multivector{Sig,K}
end
struct DualFlatBlade{Sig,K} <: CGABlade{Sig,K}
	p::Multivector{Sig,1}
	E::Multivector{Sig,K}
end
struct RoundBlade{Sig,K} <: CGABlade{Sig,K}
	p::Multivector{Sig,1}
	E::Multivector{Sig,K}
	r2::Float64
end

Multivector(X::DirectionBlade{Sig}) where Sig = embed(X.E) ∧ infinity(CGA{Sig})
Multivector(X::FlatBlade{Sig}) where Sig = let (o, oo) = (origin(CGA{Sig}), infinity(CGA{Sig}))
	translate(X.p, o ∧ embed(X.E) ∧ oo)
end
Multivector(X::DualFlatBlade{Sig}) where Sig = translate(X.p, embed(X.E))
Multivector(X::RoundBlade{Sig}) where Sig = let (o, oo) = (origin(CGA{Sig}), infinity(CGA{Sig}))
	translate(X.p, (o + 2\X.r2*oo) ∧ embed(X.E))
end

showformula(::Type{<:DirectionBlade}) = "E∧oo"
showformula(::Type{<:FlatBlade}) = "translate(p, o∧E∧oo)"
showformula(::Type{<:DualFlatBlade}) = "translate(p, E)"
showformula(::Type{<:RoundBlade}) = "translate(p, (o + r2/2*oo)∧E)"

function Base.show(io::IO, mime::MIME"text/plain", X::T) where T <: CGABlade{Sig,K} where {Sig,K}
	print(io, T, " of the form ")
	printstyled(io, showformula(T), color=:cyan)
	print(io, ":")
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

function standardform(X::AbstractMultivector{<:CGA})
	o = origin(signature(X))
	oo = infinity(signature(X))

	zeroish(X) = isapprox(X, 0, atol=sqrt(eps(float(eltype(X)))))

	if zeroish(X ∧ oo)
		if X ⨽ oo ≈ 0
			E = -unembed(X⨽o)
			DirectionBlade(E)
		else
			Xo = X⨽o # equal to -(o + p)∧E
			p = dn(X⨽Xo) # project origin onto X
			E = unembed(oo⨼Xo)
			FlatBlade(p, E)
		end
	else
		if zeroish(X ⨽ oo)
			# flat = standardform(hodgedual(X))
			# DualFlatBlade(flat.p, invhodgedual(flat.E))
			E = unembed(-(X ∧ oo)⨽o)
			if isscalar(E)
				DualFlatBlade(dn(o), E)
			else
				p = -E⨽unembed(X⨽o)/abs2(E)
				DualFlatBlade(p, E)
			end
		else
			p = dn(sandwich_prod(X, oo))
			E = -involution(unembed(X ⨽ oo))
			r2 = (X⊙involution(X))/(E⊙E)
			RoundBlade(p, E, r2)
		end
	end
end


opns(X::DirectionBlade) = :∞

opns(X::DualFlatBlade) = :∅

opns(X::FlatBlade) = Flat(X.p, X.E)

opns(X::RoundBlade) = Round(Flat(X.p, X.E), X.r2)


end