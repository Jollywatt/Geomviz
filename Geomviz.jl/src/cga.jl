module Conformal

using GeometricAlgebra
import ..Geomviz: encode, dn, normalize

export origin, infinity

"""
Metric signature for the conformal geometric algebra over ``n``-dimensional Euclidean space.
"""
abstract type CGA{n} end

GeometricAlgebra.dimension(P::Type{CGA{n}}) where n = n + 2
GeometricAlgebra.basis_vector_square(P::Type{CGA{n}}, i::Integer) where n = i == n + 2 ? -1 : 1
function GeometricAlgebra.get_basis_display_style(::Type{CGA{n}}) where {n}
	indices = [string.(1:n); "p"; "m"]
	BasisDisplayStyle(n + 2; indices)
end


"""
	origin(CGA{n})
	infinity(CGA{n})

The point at the origin `e₀` and the point at infinity `e∞` in the `n`-dimensional
conformal geometric algebra model, using the convention
``e₀ = (e₊ + e₋)/2`` and ``e∞ = e₋ - e₊``.
"""
origin(::Type{CGA{n}}) where n = Multivector{CGA{n},1}([zeros(n); 0.5; 0.5])

@doc (@doc origin)
infinity(::Type{CGA{n}}) where n = Multivector{CGA{n},1}([zeros(n); -1; +1])

origin(a::Multivector) = origin(signature(a))
infinity(a::Multivector) = infinity(signature(a))

embed(x::Multivector{Sig,1}) where Sig = Multivector{CGA{Sig},1}([x.comps; 0; 0])

function up(x::Multivector{Sig,1}) where Sig
	o, oo = origin(CGA{Sig}), infinity(CGA{Sig})
	o + embed(x) + 2\(x⊙x)*oo
end
up(x::BasisBlade) = up(Multivector(x))
up(comps::AbstractVector) = up(Multivector{length(comps),1}(comps))
up(comps...) = up(Multivector{length(comps),1}(comps...))

function normalize(X::Multivector{<:CGA,1})
	o, oo = origin(X), infinity(X)
	X/-(oo⊙X)
end


basecomps(a::Multivector{CGA{n},1}) where n = a.comps[1:n]
dn(x::Multivector{CGA{n},1}) where n = basecomps(normalize(x))



function encode(X::Multivector{CGA{3},1})
	o, oo = origin(X), infinity(X)

	norm = -(oo⊙X)
	if abs(norm) < eps()
		# has no o component; is a plane
		# X = n⃗ + d e∞
		normal = basecomps(X)
		δ = -(o⊙X)
		moment = δ*normal/sum(abs2, normal)
		Dict(
			"Rig"=>"Checker Plane",
			"Location"=>moment,
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
	o, oo = origin(X), infinity(X)
	carrier::Grade{4} = X∧oo
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
	o, oo = origin(X), infinity(X)
	circle = o∧hodgedual(X)
	(; location, normal) = circleparts(circle)
	(moment=location, direction=normal)

end

function encode(X::Multivector{CGA{3},3})
	o, oo = origin(X), infinity(X)

	n = X∧oo
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

end