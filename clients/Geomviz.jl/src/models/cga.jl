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

# using GeometricAlgebra
import ..Geomviz: Rig, encode

using GeometricAlgebra
using BladeBasedModels.Conformal
using BladeBasedModels.Conformal: DirectionBlade, FlatBlade, DualFlatBlade, RoundBlade
using BladeBasedModels.Conformal: EmptySet, PointAtInfinity, FlatGeometry, RoundGeometry


signsqrt(x) = sign(x)sqrt(abs(x))


#= encoding CGABlade subtypes =#

struct TangentBlade{Sig,K} <: CGABlade{Sig,K}
	E::Multivector{Sig,K}
	p::Multivector{Sig,1}
end

encode(X::AbstractMultivector{<:CGA}) = encode(standardform(X))
encode(X::AbstractMultivector{CGA}) = encode(GeometricAlgebra.signature_convert(Val(CGA{3}), X))

encode(X::DirectionBlade) = encode(opns(X)) # always just the point at infinity
encode(X::FlatBlade) = encode(opns(X))
encode(X::DualFlatBlade) = encode(ipns(X))
function encode(X::RoundBlade)
	if X.r2 == 0
		encode(TangentBlade(X.E, X.p))
	else
		encode(X.r2 > 0 ? opns(X) : ipns(X))
	end
end


#= encoding CGAGeometry subtypes =#

const Point = RoundGeometry{3,0}
const PointPair = RoundGeometry{3,1}
const Circle = RoundGeometry{3,2}
const Sphere = RoundGeometry{3,3}

const PointFlat = FlatGeometry{3,0}
const Line = FlatGeometry{3,1}
const Plane = FlatGeometry{3,2}

const TangentPoint = TangentBlade{3,0}
const TangentVector = TangentBlade{3,1}
const TangentPlane = TangentBlade{3,2}

encode(geom::Union{EmptySet,PointAtInfinity}) = Rig("Empty")

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

function encode(X::Union{PointFlat,TangentPoint})
	Rig("Point", location=X.p)
end

encode(X::TangentVector) = Rig("Arrow Vector",
	location=X.p,
	"Vector"=>X.E,
)

encode(X::TangentPlane) = Rig("Spear Circle",
	location=X.p,
	"Normal"=>rdual(X.E),
	"Radius"=>signsqrt(X.E⊙X.E),
)

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


end