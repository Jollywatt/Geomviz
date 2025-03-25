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
dn1d(a::BasisBlade; k...) = dn1d(Multivector(a); k...)

normalize(P::Multivector{<:Spherical,1}) = P/sqrt(P⊙P)

function encode(P::Multivector{Spherical{Sig},1}) where Sig
	p = dn1d((P))
	Dict(
		"Rig"=>"Point",
		"Location"=>Vector(p.comps),
		"Radius"=>0.05,
		"Color"=>(1,1,1,1),
	)
end

smallpoints(Ps; color) = map(Ps) do P

	p = dn1d(normalize(P))
	Dict(
		"Rig"=>"Point",
		"Location"=>Vector(p.comps),
		"Radius"=>0.025,
		"Color"=>color
	)
end

Base.abs2(a::Multivector) = scalar_prod(a, a)


function encode(C::Multivector{Spherical{Sig},2}) where Sig
	o = basis(signature(C), 1, dimension(C))

	plane = wedge(C, o)
	point = inner(C, o)


	planesize = abs(abs2(plane))
	obj = if planesize < eps()
		# line
		Dict(
			"Rig"=>"Spear Line",
			"Direction"=>point.comps[1:end-1],
			"Use separation"=>false,
			"Arrow count"=>0,
		)

	else
		# circle
		dist = sqrt(abs2(point)/planesize)
		r = sqrt(1 + dist^2)

		normal = rdual(plane)

		if abs(abs2(point)) < eps()
			Dict(
				"Rig"=>"Spear Circle",
				"Location"=>(0,0,0),
				"Normal"=>normal.comps[1:end-1],
				"Radius"=>r,
				"Arrow count"=>0,
			)
		else
			perp = normalize(inner(inner(plane, o), point))
			Dict(
				"Rig"=>"Spear Circle",
				"Location"=> perp.comps[1:end-1]*dist,
				"Normal"=>normal.comps[1:end-1],
				"Radius"=>r,
				"Arrow count"=>0,
			)
		end

	end

	if true
		# randomly sample points on line/circle
		Ps = randn(Multivector{Spherical{Sig},1}, 500)
		Qs = inner.(Ps, C) # points lying on circle/line
		[
			smallpoints(Qs; color=(1,0,1,1));
			obj
		]
	else
		obj
	end


end

function encode(S::Multivector{Spherical{Sig},3}) where Sig
	Ls = randn(Multivector{Spherical{Sig},2}, 300)
	Qs = inner.(Ls, S) # points lying on sphere/plane
	smallpoints(Qs; color=(0,1,1,1))
end
