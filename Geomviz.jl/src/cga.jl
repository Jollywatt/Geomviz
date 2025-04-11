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

"""
Metric signature for the conformal geometric algebra over ``n``-dimensional Euclidean space.
"""
abstract type CGA{n} end

GeometricAlgebra.dimension(P::Type{CGA{n}}) where n = n + 2
GeometricAlgebra.basis_vector_square(P::Type{CGA{n}}, i::Integer) where n = GeometricAlgebra.basis_vector_square(Cl(n + 1, 1), i)
# function GeometricAlgebra.get_basis_display_style(::Type{CGA{n}}) where {n}
# 	indices = [string.(1:n); "p"; "m"]
# 	BasisDisplayStyle(n + 2; indices)
# end


"""
	origin(CGA{n})
	infinity(CGA{n})

The point at the origin `e₀` and the point at infinity `e∞` in the `n`-dimensional
conformal geometric algebra model, using the convention
``e₀ = (e₊ + e₋)/2`` and ``e∞ = e₋ - e₊``.
"""
origin, infinity

origin(::Type{CGA{n}}) where n = Multivector{CGA{n},1}([zeros(n); -0.5; 0.5])
infinity(::Type{CGA{n}}) where n = Multivector{CGA{n},1}([zeros(n); +1; +1])

origin(a::Multivector) = origin(signature(a))
infinity(a::Multivector) = infinity(signature(a))


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
	o, oo = origin(X), infinity(X)
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
	CGAObject{N,K,D}

A blade in `CGA{N}` of grade `K` representing a `D`-dimensional
object in Euclidean `N`-space.
"""
abstract type CGAObject{N,K,D} end

struct Flat{N,K,D} <: CGAObject{N,K,D}
	location::Multivector{N,1}
	direction::Multivector{N,D}
end
struct Round{N,K,D} <: CGAObject{N,K,D}
	carrier::Flat{N,K,D}
	radius::Float64
end
struct Tangent{N,K,D} <: CGAObject{N,K,D}
	carrier::Flat{N,K,D}
end

location(x::Flat) = x.location
location(x::Union{Round,Tangent}) = location(x.carrier)

direction(x::Flat) = x.direction
direction(x::Union{Round,Tangent}) = direction(x.carrier)

radius(x::Round) = x.radius
radius(x::Tangent)::Float64 = 0

const PointPair = Round{2}
const Circle = Round{3}
const Sphere = Round{4}

const PointFlat = Flat{2}
const Line = Flat{3}
const Plane = Flat{4}


encode(x::PointFlat) = rig(
	"Point",
	location=location(x),
)

encode(x::PointPair) = rig("PointPair",
	location=location(x),
	"Direction"=>direction(x),
	"Radius"=>radius(x)
)

encode(x::Circle) = rig("Spear Circle",
	location=location(x),
	"Normal"=>1
)

function classify(x::Union{[Multivector{CGA{3},K} for K in 1:4]...})
	o, oo = origin(x), infinity(x)

	if x ∧ oo ≈ 0
		# flats
		if x ⨽ oo ≈ 0

		end
	else
		# rounds
		if x ⨽ oo ≈ 0
			:ff
		else
			loc = dn(sandwich_prod(x, oo))
			dir = unembed((x ⨽ -oo) ∧ oo)
			ρ² = x⊙x
			ρ = sign(ρ²)sqrt(abs(ρ²))
			Round{3,grade(x),grade(dir)}(
				Flat{3,grade(x),grade(dir)}(loc, dir),
				ρ
			)
		end
	end

end


function encode(X::Multivector{CGA{3},1})
	o, oo = origin(X), infinity(X)

	norm = -(oo⊙X)
	if abs(norm) < eps()
		# has no o component; is a plane
		# X = n⃗ + d e∞
		normal = basecomps(X)
		δ = -(o⊙X)
		moment = δ*normal/sum(abs2, normal)
		rig("Checker Plane",
			location=moment,
			show_wire=true,
			"Normal"=>normal,
			"Holes"=>false,
		)

	else
		X /= norm
		x = basecomps(X)
		ρ² = X⊙X
		if abs(ρ²) < 1e-3
			rig("Point",
				location=x,
			)
		else
			rig("Sphere",
				location=x,
				"Radius"=>sqrt(abs(ρ²)),
				"Imaginary"=>ρ² < 0,
			)
		end
	end

end

function pointpair_from_bivector(pointpair::Multivector{CGA{3},2})
	circle = hodgedual(pointpair)
	parts = circleparts(circle)
	rig("Point Pair",
		location=parts.location,
		"Radius"=>parts.radius,
		"Direction"=>parts.normal,
	)
end

function encode(X::Multivector{CGA{3},2})
	o, oo = origin(X), infinity(X)

	square = X⊙X

	if abs(square) < sqrt(eps())
		# tangent
		A = X⋅oo
		direction = unembed(A).comps
		location = unembed(X⨽inv(A)).comps
		rig("Arrow Vector",
			location=location,
			"Vector"=>direction,
		)

	else
		pointpair_from_bivector(X)
	end

end

function circleparts(X::Multivector{CGA{3},3})
	o, oo = origin(X), infinity(X)
	carrier::Grade{4} = X∧oo
	container::Grade{4} = X∧hodgedual(carrier)
	dualsphere::Grade{1} = normalize(hodgedual(container))
	x = basecomps(dualsphere)
	ρ² = dualsphere⊙dualsphere
	normal = basecomps(hodgedual(carrier))
	(
		location=x,
		radius=sign(ρ²)sqrt(abs(ρ²)),
		normal=normal,
	)
end

function lineparts(X::Multivector{CGA{3},3})
	o, oo = origin(X), infinity(X)
	circle = o∧hodgedual(X)
	(; location, normal) = circleparts(circle)
	(moment=location, direction=normal)

end

function encode(X::Multivector{CGA{3},3})
	o, oo = origin(X), infinity(X)

	if abs(X⊙X) < eps()
		A = X⋅-oo
		normal = rdual(unembed(A))
		location = unembed(X⨽inv(A)).comps
		return rig("Circle 2-blade",
			location=location,
			"Normal"=>normal.comps,
			"Radius"=>sqrt(abs2(normal)),
		)
	end

	n = X∧oo
	if abs(n⊙n) < 1e-3
		parts = lineparts(X)
		rig("Spear Line",
			location=parts.moment,
			"Direction"=>parts.direction,
			"Use separation"=>false,
			"Arrow count"=>0
		)
	else
		parts = circleparts(X)
		rig(
			"Spear Circle",
			location=parts.location,
			"Radius"=>parts.radius,
			"Normal"=>parts.normal,
			"Arrow count"=>0,
			"Imaginary"=>parts.radius < 0,
		)
	end
end

function encode(X::Multivector{CGA{3},4})
	encode(hodgedual(X))
end

end