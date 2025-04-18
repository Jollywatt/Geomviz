"""
# Projective geometric algebra

Module containing recipes for point- or plane-based projective geometric algebras.

To any algebra with metric signature `Sig` we can associate a projectivies algebra
`ProjectiveSignature{Sig}` with an additional dimension.
This extra dimension (displayed as `v0`) acts as a _homogeneous coordinate_ to allow
the representation of linear subspaces not containing the origin.
"""
module Projective

using GeometricAlgebra
using GeometricAlgebra: replace_signature
import ..Geomviz: rig, encode

"""
	ProjectiveSignature{Sig,Index,PlaneBased}

Metric signature for a projective geometric algebra.

The projective algebra has metric signature `Sig`
(and is identical to `Sig` in terms of the algebra it represents)
but signifies that the basis vector at index `Index::Integer` should be interpreted
as the projective dimension.

If `PlaneBased = true`, then ``(n - 1)``-vectors are interpreted as points
(as in plane-based projective geometric algebra), and if `PlaneBased = false`
then ``1``-vectors are interpreted as projective points (as in point-based PGA).
"""
abstract type ProjectiveSignature{Sig,Index,Repr} end


basesig(::Type{<:ProjectiveSignature{Sig}}) where Sig = Sig

GeometricAlgebra.dimension(P::Type{<:ProjectiveSignature}) = dimension(basesig(P))
GeometricAlgebra.basis_vector_square(P::Type{<:ProjectiveSignature}, i::Integer) = GeometricAlgebra.basis_vector_square(basesig(P), i)

function GeometricAlgebra.get_basis_display_style(::Type{<:ProjectiveSignature{Sig,I}}) where {Sig,I}
	n = dimension(Sig)
	indices = string.(1:(n - 1))
	insert!(indices, I, "0")
	BasisDisplayStyle(n; indices)
end

"""
	PGA{Sig} = ProjectiveSignature{Sig,1,true}

Metric signature for _plane-based_ projective geometric algebra.
"""
const PGA{Sig} = ProjectiveSignature{Sig,1,true}


const PointBasedEuclidean = ProjectiveSignature{4,I,false} where I

originvector(sig::Type{<:ProjectiveSignature{Sig,I}}) where {Sig,I} = basis(sig, 1, I)

projcomp(a::Multivector{<:ProjectiveSignature{Sig,I},1}) where {Sig,I} = a.comps[I]
function nonprojcomps(a::Multivector{<:ProjectiveSignature{Sig,I},1}) where {Sig,I}
	if I == 1
		a.comps[2:end]
	elseif I == dimension(Sig)
		a.comps[1:end - 1]
	else
		error("$ProjectiveSignature only supports the first or last dimension as the projective dimension.")
	end
end

projpoint(a::Grade{1}) = nonprojcomps(a)/projcomp(a)

function up(::Type{<:ProjectiveSignature{Sig,I,Repr} where Sig}, a::Grade{1}) where {I,Repr}
	up(ProjectiveSignature{signature})
end

function up(sig::Type{ProjectiveSignature{UpSig,I,false}}, a::Multivector{Sig,1}) where {UpSig,Sig,I}
	@assert dimension(UpSig) == dimension(Sig) + 1
	comps = insert!(Vector(a.comps), I, 1)
	Multivector{sig,1}(comps)
end
function up(sig::Type{ProjectiveSignature{UpSig,I,true}}, a::Multivector) where {UpSig,I}
	dual = rdual(up(ProjectiveSignature{UpSig,I,false}, a))
	Multivector{sig,dimension(sig) - 1}(dual.comps)
end

# vector as point
encode(a::Multivector{<:PointBasedEuclidean,1}) = rig("Point",
	location=projpoint(a),
)

# bivector as line
function encode(line::Multivector{<:PointBasedEuclidean,2})
	v0 = originvector(signature(line))
	point = (v0∧rdual(line))∨line
	direction = nonprojcomps(point⋅line)

	norm = sqrt(sum(abs2, direction))
	rig("Line",
		location=projpoint(point),
		"Direction"=>direction,
		# "Arrow separation"=>norm
	)
end

# trivector as plane
function encode(plane::Multivector{<:PointBasedEuclidean,3})
	v0 = originvector(signature(plane))
	reciprocal_point = rdual(plane)::Grade{1}
	origin = projpoint((v0∧reciprocal_point)∨plane)
	normal = nonprojcomps((rdual(plane)∧v0)⨽v0)

	rig("Plane",
		location=origin,
		show_wire=true,
		"Normal"=>normal,
		"Holes"=>false,
	)
end

# plane-based subspaces
function encodable(a::Multivector{ProjectiveSignature{Sig,I,PlaneBased}}) where {Sig,I,PlaneBased}
	pointbased = PlaneBased ? rdual(a) : a
	euclideansig = ProjectiveSignature{dimension(Sig),I,false}
	replace_signature(pointbased, Val(euclideansig))
end

function encode(a::Multivector{ProjectiveSignature{Sig,I,true}}) where {Sig,I}
	pointbased = rdual(a)
	euclideansig = ProjectiveSignature{Sig,I,false}
	encode(replace_signature(pointbased, Val(euclideansig)))
end

end