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
import ..Geomviz: rig, encode, dn, normalize

export origin, infinity
export classify
export Flat, PointFlat, Line, Plane
export Round, PointPair, Circle, Sphere
export Tangent, Point


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


origin(::Type{CGA{n}}) where n = Multivector{CGA{n},1}([zeros(n); -0.5; 0.5])
infinity(::Type{CGA{n}}) where n = Multivector{CGA{n},1}([zeros(n); +1; +1])
"""
	origin(CGA{n})
	infinity(CGA{n})

The point at the origin `e₀` and the point at infinity `e∞` in the `n`-dimensional
conformal geometric algebra model, using the convention
``e₀ = (e₊ + e₋)/2`` and ``e∞ = e₋ - e₊``.
"""
origin, infinity


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
	o + embed(x) + 2\(x⊙x)*oo
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
	CGAObject{D,Sig}

A blade in `CGA{Sig}` with a `D`-dimensional carrier.
"""
abstract type CGAObject{D,Sig} end


"""
	Flat{D,Sig}

A blade of the forn
``Tₚ[o ∧ E ∧ oo]``
"""
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


encode(x::Union{Point,PointFlat}) = rig("Point", location=location(x))

encode(x::PointPair) = rig("Point Pair",
	location=location(x),
	"Direction"=>direction(x),
	"Radius"=>radius(x)
)

encode(x::Circle) = rig("Spear Circle",
	location=location(x),
	"Radius"=>radius(x),
	"Normal"=>rdual(direction(x)),
)

encode(x::Union{Sphere,Round{0}}) = rig("Sphere",
	location=location(x),
	"Radius"=>abs(radius(x)),
	"Imaginary"=>radius(x) < 0,
)

encode(x::Line) = rig("Spear Line",
	location=location(x),
	"Direction"=>direction(x),
)

encode(x::Plane) = rig("Checker Plane",
	location=location(x),
	"Normal"=>rdual(direction(x)),
)

encode(x::Tangent{1}) = rig("Arrow Vector",
	location=location(x),
	"Vector"=>direction(x),
)

encode(x::Tangent{2}) = rig("Circle 2-blade",
	location=location(x),
	"Normal"=>rdual(direction(x)),
)


function classify(x::AbstractMultivector{<:CGA})
	o, oo = origin(signature(x)), infinity(signature(x))

	x² = x*x
	isapprox(x², scalar(x²), atol=sqrt(eps())) || return nothing

	if x ∧ oo ≈ 0
		if x ⨽ oo ≈ 0
			# directions
			dir = unembed(x ⨽ -o)
			Direction(dir)
		else
			# flats
			loc = dn(x⨽(x⨽o))
			dir = unembed(involution(x)⨽(o∧oo))
			Flat(loc, dir)
		end
	else
		y = x ⨽ oo
		if y ≈ 0
			# dual flats
			classify(hodgedual(x))
		else
			# rounds
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

encode(x::Multivector{CGA{3}}) = encode(classify(x))

end