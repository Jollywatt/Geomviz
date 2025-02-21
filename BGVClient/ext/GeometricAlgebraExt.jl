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

const Grade{K} = Union{BasisBlade{Sig,K},Multivector{Sig,K}} where Sig

GeometricAlgebra.basis(sig, k, i) = BasisBlade{sig,k}(1, collect(GeometricAlgebra.componentbits(sig,k))[i])

pgapoint(a::Multivector{PGA{3},1}) = Vector(a.comps[2:4]/a.comps[1])

encode(a::Multivector{PGA{3},1}) = Dict("Simple Point" => [pgapoint(a)])

function encode(B::Multivector{PGA{3},2})
	normal = rdual(B)
	e0 = basis(PGA{3}, 1, 1)
	plane = e0∧normal
	m = ldual(rdual(plane)∧rdual(B))
	d = B⋅m
	Dict("Infinite Line" => [(pgapoint(m), pgapoint(m + d))])
end

function encode(plane::Multivector{PGA{3},3})
	point = rdual(plane)
	e0 = basis(PGA{3}, 1, 1)
	normal = e0∧point
	m = ldual(rdual(normal)∧rdual(plane))::Grade{1}
	Dict("Infinite Grid" => [(pgapoint(m), pgapoint(m + point))])
end

end # module