module LieSphereGeometry

using GeometricAlgebra
import ..Geomviz: rig, encode, dn, normalize, classify

import ..Geomviz.Conformal: CGA

export LSG


abstract type LSG{N} end


GeometricAlgebra.dimension(::Type{LSG{Sig}}) where Sig = dimension(Sig) + 3
function GeometricAlgebra.basis_vector_square(::Type{LSG{Sig}}, i::Integer) where Sig
	(GeometricAlgebra.canonical_signature(Sig)..., +1, -1, -1)[i]
end

toquadric(x::Multivector{CGA{Sig},1}, orientation) where Sig = toquadric(embed(LSG{Sig}, x), orientation)
function toquadric(x::Multivector{<:LSG,1}, orientation)
	v0 = basis(signature(x), 1, dimension(x))
	x + orientation*sqrt(x⊙x)*v0
end

function GeometricAlgebra.get_basis_display_style(::Type{LSG{Sig}}) where Sig
	n = dimension(Sig)
	BasisDisplayStyle(n + 3, indices=[string.(1:n); "p"; "m"; "0"])
end

function origin(::Type{LSG{Sig}}) where Sig
	vp = basis(LSG{Sig}, 1, dimension(Sig) + 1)
	vm = basis(LSG{Sig}, 1, dimension(Sig) + 2)
	2\(vm + vp)
end
function infinity(::Type{LSG{Sig}}) where Sig
	vp = basis(LSG{Sig}, 1, dimension(Sig) + 1)
	vm = basis(LSG{Sig}, 1, dimension(Sig) + 2)
	vm - vp
end

function extras(::Type{LSG{Sig}}) where Sig
	vp, vm, v0 = (basis(LSG{Sig}, 1, dimension(Sig) + i) for i in 1:3)
	o = 2\(vm - vp)
	oo = vm + vp
	o, oo, v0
end


function twiddle(x::Multivector{LSG{Sig},1}) where Sig
	comps = Vector(x.comps)
	comps[end-1] *= -1
	Multivector{LSG{Sig},1}(comps)
end

encode(x::Multivector{LSG{3},1}) = encode(embed(CGA{3}, x))


end 