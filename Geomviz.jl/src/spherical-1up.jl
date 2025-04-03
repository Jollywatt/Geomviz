module SphericalOneUp

using GeometricAlgebra
import ..Geomviz: rig, encode, dn, normalize

"""
Metric signature for the spherical 1d-up geometric algebra over ``n``-dimensional Euclidean space.
"""
abstract type SGA{Sig} end

const CURVATURE = Ref{Float64}(1)


basesig(::Type{<:SGA{Sig}}) where Sig = Sig

GeometricAlgebra.dimension(sig::Type{<:SGA}) = dimension(basesig(sig)) + 1
GeometricAlgebra.basis_vector_square(sig::Type{<:SGA}, i::Integer) = i <= dimension(sig) ? GeometricAlgebra.basis_vector_square(basesig(sig), i) : 1

function GeometricAlgebra.get_basis_display_style(sig::Type{<:SGA})
	n = dimension(sig)
	indices = string.(1:(n - 1))
	push!(indices, "0")
	BasisDisplayStyle(n; indices)
end

embed(::Type{SGA{Sig}}, a::Multivector{Sig,1}) where Sig = Multivector{SGA{Sig},1}([a.comps; 0])
embed(::Type{SGA{Sig}}, a::BasisBlade) where Sig = embed(SGA{Sig}, Multivector(a))

function up(p::Grade{1,Sig}; λ=CURVATURE[]) where Sig
	p² = p⊙p
	e0 = basis(SGA{Sig}, 1, dimension(Sig) + 1)
	(2λ*embed(SGA{Sig}, p) + (λ^2 - p²)e0)/(λ^2 + p²)
end
up(comps...; kw...) = up(Multivector{length(comps),1}(comps); kw...)

function dn(P::Multivector{SGA{Sig},1}; λ=CURVATURE[]) where Sig
	p = Multivector{Sig,1}(P.comps[1:end-1])
	λ*p/(1 + P.comps[end])
end
dn(a::BasisBlade; k...) = dn(Multivector(a); k...)

normalize(P::Multivector{<:SGA}) = P/sqrt(abs(P⊙P))

function encode(P::Multivector{SGA{Sig},1}) where Sig
	p = dn(P)
	rig("Point",
		location=Vector(p.comps),
		"Radius"=>0.05,
		color=(1,1,1,1),
	)
end

smallpoints(Ps; color) = map(Ps) do P

	p = dn(normalize(P))
	rig("Point",
		location=Vector(p.comps),
		"Radius"=>0.025,
		color=color
	)
end

Base.abs2(a::Multivector) = scalar_prod(a, a)


function encode(C::Multivector{SGA{Sig},2}) where Sig
	o = basis(signature(C), 1, dimension(C))

	plane = wedge(C, o)
	point = inner(C, o)


	planesize = abs(abs2(plane))
	if planesize < eps()
		# line through origin
		obj = rig("Spear Line",
			lirection=point.comps[1:end-1],
			"Use separation"=>false,
			"Arrow count"=>0,
		)

	else
		# circle
		normal = dn(rdual(plane))
		centerpoint = dn(normalize(sandwich_prod(C, o)))
		r = sqrt(abs2(centerpoint) + CURVATURE[]^2)

		obj = rig("Spear Circle",
			location=centerpoint.comps,
			"Normal"=>normal.comps,
			"Radius"=>r,
			"Arrow count"=>0,
		)

	end

	if false
		# randomly sample points on line/circle
		Ps = randn(Multivector{SGA{Sig},1}, 200)
		Qs = inner.(Ps, C) # points lying on circle/line
		[
			smallpoints(Qs; color=(1,0,1,1));
			# obj
		]
	else
		obj
	end


end

function encode(S::Multivector{SGA{Sig},3}) where Sig
	o = basis(signature(S), 1, dimension(S))

	if iszero(S∧o)
		# plane through origin
		normal = dn(rdual(S))
		obj = rig("Checker Plane",
			location=(0,0,0),
			"Normal"=>normal.comps
		)
	else
		# sphere
		center = dn(normalize(-sandwich_prod(S, o)))
		ρ = sqrt(abs2(center) + CURVATURE[]^2)

		obj = rig("Sphere",
			location=center.comps,
			"Radius"=>ρ,
			color=(1,1,1,0.7),
		)
	end

	if false
		Ls = randn(Multivector{SGA{Sig},2}, 200)
		Qs = inner.(Ls, S) # points lying on sphere/plane
		[smallpoints(Qs; color=(0,1,1,1))]
	else
		obj
	end

end


end