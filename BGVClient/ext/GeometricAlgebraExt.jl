module GeometricAlgebraExt

using BGVClient, GeometricAlgebra

import BGVClient: encode


encode(a::BasisBlade) = encode(Multivector(a))
encode(a::Multivector{3,1}) = Dict(
	"Arrow Vector" => [Vector(a.comps)]
)

encode(a::Multivector{3,2}) = Dict(
	"Circle 2-blade" => [Vector(rdual(a).comps)]
)



end # module