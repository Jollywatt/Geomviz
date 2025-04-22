module SphericalOneUp

using GeometricAlgebra
import ..Geomviz: rig, encode, dn, normalize, classify

using Base.ScopedValues

"""
Metric signature for the spherical 1d-up geometric algebra over ``n``-dimensional Euclidean space.
"""
abstract type SGA{Sig} end

const CURVATURE = ScopedValue(1.0)

basesig(::Type{<:SGA{Sig}}) where Sig = Sig

GeometricAlgebra.dimension(sig::Type{<:SGA}) = dimension(basesig(sig)) + 1
GeometricAlgebra.basis_vector_square(sig::Type{<:SGA}, i::Integer) = i <= dimension(sig) ? GeometricAlgebra.basis_vector_square(basesig(sig), i) : 1

function GeometricAlgebra.get_basis_display_style(sig::Type{<:SGA})
	n = dimension(sig)
	indices = string.(1:(n - 1))
	push!(indices, "0")
	BasisDisplayStyle(n; indices)
end

embed(a::AbstractMultivector{Sig}) where Sig = GeometricAlgebra.embed(SGA{Sig}, a)
unembed(a::AbstractMultivector{SGA{Sig}}) where Sig = GeometricAlgebra.embed(Sig, a)

function up(p::Grade{1,Sig}; λ = CURVATURE[]) where Sig
	p² = p⊙p
	Multivector{SGA{Sig},1}([2λ*p.comps; λ^2 - p²])/(λ^2 + p²)
end
up(comps...; kw...) = up(Multivector{length(comps),1}(comps); kw...)

function dn(P::Multivector{SGA{Sig},1}; λ = CURVATURE[]) where Sig
	p = Multivector{Sig,1}(P.comps[1:end-1])
	λ*p/(1 + P.comps[end])
end
dn(a::BasisBlade; k...) = dn(Multivector(a); k...)

normalize(P::Multivector{<:SGA}) = P/sqrt(abs(P⊙P))


smallpoints(Ps; color) = map(Ps) do P

	p = dn(normalize(P))
	rig("Point",
		location=Vector(p.comps),
		"Radius"=>0.025,
		color=color
	)
end

Base.abs2(a::Multivector) = scalar_prod(a, a)

origin(sig::Type{SGA{Sig}}) where Sig = basis(sig, 1, dimension(sig))
center(S) = (-1)^grade(S)*normalize(sandwich_prod(S, origin(signature(S))))
radius(S) = sqrt(abs2(dn(center(S))) + CURVATURE[]^2)

abstract type SGAObject{D,Sig} end
struct Flat{D,Sig} <: SGAObject{D,Sig}
	location::Multivector{Sig,1}
	direction::Multivector{Sig,D}
end
struct Round{D,Sig} <: SGAObject{D,Sig}
	carrier::Flat{D,Sig}
	radius::Float64
end

function classify(S::AbstractMultivector{SGA{Sig}}) where Sig
	k = only(grade(S))
	oo = -basis(signature(S), 1, dimension(S))
	C = center(S)
	if C ≈ oo
		dir = unembed(Multivector(S⨽oo))
		loc = zero(Multivector{Sig,1})
		Flat(loc, dir)
	else
		loc = dn(C)
		dir = unembed((S∧oo)⨽oo)
		Round(Flat(loc, dir), radius(S))
	end
end

encode(x::Flat{0,3}) = rig("Point")
encode(x::Flat{1,3}) = rig("Line", "Direction"=>x.direction)
encode(x::Flat{2,3}) = rig("Plane", "Normal"=>rdual(x.direction))
encode(x::Round{1,3}) = rig("Point Pair",
	location=x.carrier.location,
	"Radius"=>x.radius,
	"Direction"=>x.carrier.direction,
)
encode(x::Round{2,3}) = rig("Circle",
	location=x.carrier.location,
	"Radius"=>x.radius,
	"Normal"=>rdual(x.carrier.direction),
)
encode(x::Round{3,3}) = rig("Sphere",
	location=x.carrier.location,
	"Radius"=>x.radius,
)


encode(a::AbstractMultivector{<:SGA}) = encode(classify(a))

end