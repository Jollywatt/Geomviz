abstract type Spherical{Sig} end


basesig(::Type{<:Spherical{Sig}}) where Sig = Sig

GeometricAlgebra.dimension(sig::Type{<:Spherical}) = dimension(basesig(sig)) + 1
GeometricAlgebra.basis_vector_square(sig::Type{<:Spherical}, i::Integer) = i <= dimension(sig) ? GeometricAlgebra.basis_vector_square(basesig(sig), i) : 1

function GeometricAlgebra.get_basis_display_style(sig::Type{<:Spherical})
	n = dimension(sig)
	indices = string.(1:(n - 1))
	push!(indices, "0")
	BasisDisplayStyle(n; indices)
end

embed(::Type{Spherical{Sig}}, a::Multivector{Sig,1}) where Sig = Multivector{Spherical{Sig},1}([a.comps; 0])
embed(::Type{Spherical{Sig}}, a::BasisBlade) where Sig = embed(Spherical{Sig}, Multivector(a))

function up1d(p::Grade{1,Sig}; λ=1) where Sig
	p² = p⊙p
	e0 = basis(Spherical{Sig}, 1, dimension(Sig) + 1)
	(2λ*embed(Spherical{Sig}, p) + (λ^2 - p²)e0)/(λ^2 + p²)
end

function dn1d(P::Multivector{Spherical{Sig},1}; λ=1) where Sig
	p = Multivector{Sig,1}(P.comps[1:end-1])
	λ*p/(1 + P.comps[end])
end



function encode(P::Multivector{Spherical{Sig},1}) where Sig
	p = dn1d(P)
	Dict(
		"Rig"=>"Point",
		"Location"=>Vector(p.comps),
	)
end


function encode(L::Multivector{Spherical{Sig},2}) where Sig
	Ps = randn(Multivector{Spherical{Sig},1}, 50)
	Qs = Ps .⨼ L # points lying on line
	Qs ./= sqrt.(Qs.⊙Qs)
	encode.(Qs)
end

function encode(S::Multivector{Spherical{Sig},3}) where Sig
	Ls = randn(Multivector{Spherical{Sig},2}, 100)
	Qs = Ls .⨼ S # points lying on sphere/plane
	Qs ./= sqrt.(Qs.⊙Qs)
	encode.(Qs)
end