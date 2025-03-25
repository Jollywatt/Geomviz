struct CGA{n} end

GeometricAlgebra.dimension(P::Type{CGA{n}}) where n = n + 2
GeometricAlgebra.basis_vector_square(P::Type{CGA{n}}, i::Integer) where n = i == n + 2 ? -1 : 1

function GeometricAlgebra.get_basis_display_style(::Type{CGA{n}}) where {n}
	indices = [string.(1:n); "p"; "m"]
	BasisDisplayStyle(n + 2; indices)
end

Base.@assume_effects :foldable function cgabasis(::Type{CGA{n}}) where n
	v..., vp, vm = basis(CGA{n})::Vector{BasisBlade{CGA{n},1,Int}}
	v0, voo = 2\(vp + vm), vm - vp
	(; v, v0, voo)
end
cgabasis(a::Multivector) = cgabasis(signature(a))
cgavoo(::Type{CGA{n}}) where n = cgabasis(CGA{n}).voo
cgav0(::Type{CGA{n}}) where n = cgabasis(CGA{n}).v0


embed(x::Multivector{Sig,1}) where Sig = Multivector{CGA{Sig},1}([x.comps; 0; 0])

function up(x::Multivector{Sig,1}) where Sig
	(; v0, voo) = cgabasis(CGA{Sig})
	v0 + embed(x) + 2\(x⊙x)*voo
end
up(x::BasisBlade) = up(Multivector(x))
up(comps::AbstractVector) = up(Multivector{length(comps),1}(comps))
up(comps...) = up(Multivector{length(comps),1}(comps...))

function normalize(X::Multivector{<:CGA,1})
	(; v0, voo) = cgabasis(X)
	X/-(voo⊙X)
end


basecomps(a::Multivector{CGA{n},1}) where n = a.comps[1:n]
dn(x::Multivector{CGA{n},1}) where n = basecomps(normalize(x))



function encode(X::Multivector{CGA{3},1})
	(; v0, voo) = cgabasis(X)

	norm = -(voo⊙X)
	if abs(norm) < eps()
		# has no v0 component; is a plane
		# X = n⃗ + d*voo
		normal = basecomps(X)
		δ = -(v0⊙X)
		origin = δ*normal/sum(abs2, normal)
		Dict(
			"Rig"=>"Checker Plane",
			"Location"=>origin,
			"Normal"=>normal,
			"Show wire"=>true,
			"Holes"=>false,
		)

	else
		X /= norm
		x = basecomps(X)
		ρ² = X⊙X
		if abs(ρ²) < 1e-3
			Dict("Rig"=>"Point", "Location"=>x)
		else
			Dict(
				"Rig"=>"Sphere",
				"Location" => x,
				"Radius" => sqrt(abs(ρ²)),
				"Imaginary" => ρ² < 0,
			)
		end
	end

end

function encode(pointpair::Multivector{CGA{3},2})
	circle = hodgedual(pointpair)
	parts = circleparts(circle)
	Dict(
		"Rig"=>"Point Pair",
		"Location"=>parts.location,
		"Radius"=>parts.radius,
		"Direction"=>parts.normal,
	)

end

function circleparts(X::Multivector{CGA{3},3})
	(; v0, voo) = cgabasis(X)
	carrier::Grade{4} = X∧voo
	container::Grade{4} = X∧hodgedual(carrier)
	dualsphere::Grade{1} = normalize(hodgedual(container))
	x = basecomps(dualsphere)
	ρ² = dualsphere⊙dualsphere
	normal = basecomps(hodgedual(carrier))
	(
		location=x,
		radius=sqrt(abs(ρ²)),
		normal=normal,
	)
end

function lineparts(X::Multivector{CGA{3},3})
	(; v0, voo) = cgabasis(X)
	circle = v0∧hodgedual(X)
	(; location, normal) = circleparts(circle)
	(moment=location, direction=normal)

end

function encode(X::Multivector{CGA{3},3})
	(; v0, voo) = cgabasis(X)

	n = X∧voo
	if abs(n⊙n) < 1e-3
		parts = lineparts(X)
		Dict(
			"Rig"=>"Spear Line",
			"Location"=>parts.moment,
			"Direction"=>parts.direction,
			"Use separation"=>false,
			"Arrow count"=>0,
		)
	else
		parts = circleparts(X)
		Dict(
			"Rig"=>"Spear Circle",
			"Location"=>parts.location,
			"Radius"=>parts.radius,
			"Normal"=>parts.normal,
			"Arrow count"=>0,
		)
	end
end

function encode(X::Multivector{CGA{3},4})
	encode(hodgedual(X))
end

