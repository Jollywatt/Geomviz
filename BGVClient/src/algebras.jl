"""
	Projective{Sig,Index,PlaneBased}

Metric signature for a projective algebra.

The projective algebra has metric signature `Sig`
(and is identical to `Sig` in terms of the algebra it represents)
but signifies that the basis vector at index `Index::Integer` should be interpreted
as the projective dimension.

If `PlaneBased = true`, then ``(n - 1)``-vectors are interpreted as points
(as in plane-based projective geometric algebra), and if `PlaneBased = false`
then ``1``-vectors are interpreted as projective points (as in point-based PGA).
"""
struct Projective{Sig,Index,Repr} end


basesig(::Type{<:Projective{Sig}}) where Sig = Sig

GeometricAlgebra.dimension(P::Type{<:Projective}) = dimension(basesig(P))
GeometricAlgebra.basis_vector_square(P::Type{<:Projective}, i::Integer) = GeometricAlgebra.basis_vector_square(basesig(P), i)


function GeometricAlgebra.get_basis_display_style(::Type{<:Projective{Sig,I}}) where {Sig,I}
	n = dimension(Sig)
	indices = string.(1:(n - 1))
	insert!(indices, I, "0")
	BasisDisplayStyle(n; indices)
end

const PGA{Sig} = Projective{Sig,0,true}


struct CGA{n} end

GeometricAlgebra.dimension(P::Type{CGA{n}}) where n = n + 2
GeometricAlgebra.basis_vector_square(P::Type{CGA{n}}, i::Integer) where n = i == n + 2 ? -1 : 1

function GeometricAlgebra.get_basis_display_style(::Type{CGA{n}}) where {n}
	indices = [string.(1:n); "p"; "m"]
	BasisDisplayStyle(n + 2; indices)
end

function cgabasis(::Type{CGA{n}}) where n
	v..., vp, vm = basis(CGA{n})
	v0, voo = 2\(vp + vm), vm - vp
	(; v, v0, voo)
end

function up(x::Multivector{Sig,1}) where Sig
	(; v, v0, voo) = cgabasis(CGA{Sig})
	X = Multivector{CGA{Sig},1}(x.comps..., 0, 0)
	v0 + X + 2\(x⊙x)*voo
end
up(comps...) = up(Multivector{length(comps),1}(comps...))