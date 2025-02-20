module GeometricAlgebraExt

using BGVClient, GeometricAlgebra

import BGVClient: encode
import GeometricAlgebra.Algebras: PGA

encode(a::BasisBlade) = encode(Multivector(a))
encode(a::Multivector{3,1}) = Dict(
	"Arrow Vector" => [Vector(a.comps)]
)

encode(a::Multivector{3,2}) = Dict(
	"Circle 2-blade" => [Vector(rdual(a).comps)]
)


GeometricAlgebra.basis(sig, k, i) = BasisBlade{sig,k}(1, collect(GeometricAlgebra.componentbits(sig,k))[i])

pgapoint(a::Multivector{PGA{3},1}) = Vector(a.comps[2:4]/a.comps[1])

encode(a::Multivector{PGA{3},1}) = Dict("Simple Point" => [pgapoint(a)])

function encode(B::Multivector{PGA{3},2})
	normal = rdual(B)
	e0 = basis(PGA{3}, 1, 1)
	plane = e0∧normal
	l1 = ldual(rdual(plane)∧rdual(B))
	l2 = l1 + B⋅l1
	Dict("Infinite Line" => [[pgapoint(l1); pgapoint(l2)]])
end

end # module