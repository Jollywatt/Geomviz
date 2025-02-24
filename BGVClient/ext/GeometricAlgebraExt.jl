module GeometricAlgebraExt

using BGVClient, GeometricAlgebra

import BGVClient: encode
import BGVClient.Pickle: List

using GeometricAlgebra: replace_signature
using GeometricAlgebra.Algebras: Projective

List(a::GeometricAlgebra.SingletonVector) = List(collect(a))

const Grade{K} = Union{BasisBlade{Sig,K},Multivector{Sig,K}} where Sig


#= VGA =#

encode(a::Multivector{3,1}) = Dict(
	"Arrow Vector" => [Vector(a.comps)]
)

encode(a::Multivector{3,2}) = Dict(
	"Circle 2-blade" => [Vector(rdual(a).comps)]
)


#= Projectivised algebras =#

const PointBasedEuclidean = Projective{4,I,false} where I

originvector(sig::Type{<:Projective{Sig,I}}) where {Sig,I} = basis(sig, 1, I)

projcomponent(a::Multivector{<:Projective{Sig,I},1}) where {Sig,I} = a.comps[I]
function nonprojcomponents(a::Multivector{<:Projective{Sig,I},1}) where {Sig,I}
	if I == 1
		a.comps[2:end]
	elseif I == dimension(Sig)
		a.comps[1:end - 1]
	else
		error("$Projective only supports the first or last dimension as the projective dimension.")
	end
end

projpoint(a::Grade{1}) = nonprojcomponents(a)/projcomponent(a)



# vector as point
encode(a::Multivector{<:PointBasedEuclidean,1}) = Dict("Simple Point" => [projpoint(a)])

# bivector as line
function encode(line::Multivector{<:PointBasedEuclidean,2})
	e0 = originvector(signature(line))
	point = (e0∧rdual(line))∨line
	direction = line⋅point
	Dict("Infinite Line" => [(projpoint(point), projpoint(point + direction))])
end

# trivector as plane
function encode(plane::Multivector{<:PointBasedEuclidean,3})
	e0 = originvector(signature(plane))
	reciprocal_point = rdual(plane)::Grade{1}
	origin = projpoint((e0∧reciprocal_point)∨plane)
	normal = nonprojcomponents((rdual(plane)∧e0)⨽e0)

	Dict("Infinite Grid" => [(origin, origin + normal)])
end

# plane-based subspaces
function encodable(a::Multivector{Projective{Sig,I,PlaneBased}}) where {Sig,I,PlaneBased}
	pointbased = PlaneBased ? rdual(a) : a
	euclideansig = Projective{dimension(Sig),I,false}
	replace_signature(pointbased, Val(euclideansig))
end


encode(a::BasisBlade) = encode(Multivector(a))
encode(a::Multivector) = encode(encodable(a))




end # module