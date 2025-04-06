 module Conformal

using GeometricAlgebra
import ..Geomviz: rig, encode, dn, normalize

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

function embed(x::Multivector{Sig,K}) where {Sig,K}
	X = zero(Multivector{CGA{Sig},K})
	for ak in eachgrade(x)
		T = Multivector{CGA{Sig},grade(ak)}
		n = ncomponents(T)
		X += T([ak.comps; zeros(n - ncomponents(ak))])
	end
	X
end

function unembed(X::Multivector{CGA{Sig},K}) where {Sig,K}
	x = zero(Multivector{Sig,K})
	for ak in eachgrade(X)
		T = Multivector{Sig,grade(ak)}
		n = ncomponents(T)
		x += T(ak.comps[1:n])
	end
	x
end

basecomps(a::Multivector{CGA{n},1}) where n = a.comps[1:n]
function basecomps(a::Multivector{CGA{n},K}) where {n,K}
	eachgrade(a) do ak
		ak.comps
	end
end

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
		rig("Checker Plane",
			location=moment,
			show_wire=true,
			"Normal"=>normal,
			"Holes"=>false,
		)

	else
		X /= norm
		x = basecomps(X)
		ρ² = X⊙X
		if abs(ρ²) < 1e-3
			rig("Point",
				location=x,
			)
		else
			rig("Sphere",
				location=x,
				"Radius"=>sqrt(abs(ρ²)),
				"Imaginary"=>ρ² < 0,
			)
		end
	end

end

function pointpair_from_bivector(pointpair::Multivector{CGA{3},2})
	circle = hodgedual(pointpair)
	parts = circleparts(circle)
	rig("Point Pair",
		location=parts.location,
		"Radius"=>parts.radius,
		"Direction"=>parts.normal,
	)
end

function encode(X::Multivector{CGA{3},2})
	o, oo = origin(X), infinity(X)

	square = X⊙X

	if abs(square) < sqrt(eps())
		# tangent
		A = X⋅oo
		direction = unembed(A).comps
		location = unembed(X⨽inv(A)).comps
		rig("Arrow Vector",
			location=location,
			"Vector"=>direction,
		)

	else
		pointpair_from_bivector(X)
	end

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
		radius=sign(ρ²)sqrt(abs(ρ²)),
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

	if abs(X⊙X) < eps()
		A = X⋅-oo
		normal = rdual(unembed(A))
		location = unembed(X⨽inv(A)).comps
		return rig("Circle 2-blade",
			location=location,
			"Normal"=>normal.comps,
			"Radius"=>sqrt(abs2(normal)),
		)
	end

	n = X∧oo
	if abs(n⊙n) < 1e-3
		parts = lineparts(X)
		rig("Spear Line",
			location=parts.moment,
			"Direction"=>parts.direction,
			"Use separation"=>false,
			"Arrow count"=>0
		)
	else
		parts = circleparts(X)
		@show parts.radius
		rig(
			"Spear Circle",
			location=parts.location,
			"Radius"=>parts.radius,
			"Normal"=>parts.normal,
			"Arrow count"=>0,
			color=parts.radius > 0 ? (1,1,1,1) : (0,0,1,0.5)
		)
	end
end

function encode(X::Multivector{CGA{3},4})
	encode(hodgedual(X))
end

end