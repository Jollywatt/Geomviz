
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
up(x::BasisBlade) = up(Multivector(x))
up(comps...) = up(Multivector{length(comps),1}(comps...))



basecomps(a::Multivector{CGA{n},1}) where n = a.comps[1:n]

function encode(X::Multivector{CGA{3},1})
	(; v0, voo) = cgabasis(signature(X))

	norm = -(voo⊙X)
	if abs(norm) < eps()
		# has no v0 component; is a plane
		normal = basecomps(X)
		ℓ = -2\(X⊙v0)
		origin = normal*ℓ
		Dict("Infinite Grid" => [(origin, origin + normal)])

	else
		X /= norm
		x = basecomps(X)
		ρ² = X⊙X
		if abs(ρ²) < 1e-3
			Dict("Simple Point" => [x])
		else
			r = sign(ρ²)sqrt(abs(ρ²))
			Dict("Simple Sphere" => [(x, r)])
		end
	end

end

function normalize(X::Multivector{<:CGA,1})
	v0, voo = cgabasis(signature(X))
	X/-(voo⊙X)
end


function encode(X::Multivector{CGA{3},4})
	encode(hodgedual(X))
end

