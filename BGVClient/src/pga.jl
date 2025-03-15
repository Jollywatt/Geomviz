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

const PGA{Sig} = Projective{Sig,1,true}



const PointBasedEuclidean = Projective{4,I,false} where I

originvector(sig::Type{<:Projective{Sig,I}}) where {Sig,I} = basis(sig, 1, I)

projcomp(a::Multivector{<:Projective{Sig,I},1}) where {Sig,I} = a.comps[I]
function nonprojcomps(a::Multivector{<:Projective{Sig,I},1}) where {Sig,I}
	if I == 1
		a.comps[2:end]
	elseif I == dimension(Sig)
		a.comps[1:end - 1]
	else
		error("$Projective only supports the first or last dimension as the projective dimension.")
	end
end

projpoint(a::Grade{1}) = nonprojcomps(a)/projcomp(a)



# vector as point
encode(a::Multivector{<:PointBasedEuclidean,1}) = Dict("Simple Point" => [projpoint(a)])

# bivector as line
function encode(line::Multivector{<:PointBasedEuclidean,2})
	v0 = originvector(signature(line))
	point = (v0∧rdual(line))∨line
	direction = line⋅point
	Dict("Infinite Line" => [(projpoint(point), projpoint(point + direction))])
end

# trivector as plane
function encode(plane::Multivector{<:PointBasedEuclidean,3})
	v0 = originvector(signature(plane))
	reciprocal_point = rdual(plane)::Grade{1}
	origin = projpoint((v0∧reciprocal_point)∨plane)
	normal = nonprojcomps((rdual(plane)∧v0)⨽v0)

	Dict("Infinite Grid" => [(origin, origin + normal)])
end

# plane-based subspaces
function encodable(a::Multivector{Projective{Sig,I,PlaneBased}}) where {Sig,I,PlaneBased}
	pointbased = PlaneBased ? rdual(a) : a
	euclideansig = Projective{dimension(Sig),I,false}
	replace_signature(pointbased, Val(euclideansig))
end

encodable(a::Grade{0}) = scalar(a)


encode(a::BasisBlade) = encode(Multivector(a))
encode(a::Multivector) = encode(encodable(a))
