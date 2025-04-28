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


# function classify(x::Multivector{<:LSG,1})
# 	abs(x⊙x) < eps() || error("not on Lie quadric, x² = $(x⊙x)")

# 	e0 = basis(signature(x), 1, dimension(x))
# 	o, oo = origin(signature(x)), infinity(signature(x))
# 	if abs(x⊙e0) < eps()
# 		missing
# 	else
# 		x̂ = x/(x⊙e0)
# 		embed(CGA{Sig}, x̂)
# 	end


# end

function twiddle(x::Multivector{LSG{Sig},1}) where Sig
	comps = Vector(x.comps)
	comps[end-1] *= -1
	Multivector{LSG{Sig},1}(comps)
end

encode(x::Multivector{LSG{3},1}) = encode(embed(CGA{3}, (x)))



function samplespherecomplex2(ξ::AbstractMultivector{LSG{Sig}}; n=10, σx=1, σr=1) where Sig
	x = σx*randn(Multivector{Sig,1}, n)
	o, oo, v0 = extras(LSG{Sig})
	p = @. o + embed(LSG{Sig}, x) + 2\abs2(x)oo
	r = σr*randn(n)
	s = @. p - 2\abs2(r)oo + r*v0

	# projection of s onto blade ξ
	# ξ = @. ξ∧s
	@. 2\(s + grade(involution(ξ)*s*reversion(ξ), 1)/abs2(ξ))
	# @. 2\(s - grade(involution(ξ)*s*inv(ξ), 1))
	# @. s - (s⋅ξ)/ξ
	# s
end

function grad(ξ, x)
	v = basis(signature(x))
	# v̂ = @. 2\(v + grade(involution(ξ)*v*reversion(ξ), 1)/abs2(ξ))
	v̂ = rej.(v, ξ)
	# x̂ = rej(x, ξ)
	@assert all(@. abs(v̂⊙ξ) < eps())
	∇ = sum(@. 2(x⊙v̂)*v̂)
end

function descend(ξ, x, stepsize=1e-2)
	for _ in 1:1000
		x = rej(ξ, x)
		∇ = grad(ξ, x)
		@assert abs(∇⊙ξ) < 1e-4

		x² = abs2(x)
		x -= x²*stepsize*∇

		abs(x²) < 1e-5 && return x
	end
end


function quadstep(ξ, x::Grade{1})
	n = dimension(x)
	vm, v0 = basis.(signature(x), 1, (n - 1, n))
	Π = vm∧v0
	∇::Grade{1} = rej(sandwich_prod(Π, x), ξ)
	a = abs2(∇)
	b = 2∇⊙x
	c = abs2(x)
	@show a b c
	λ = real(-b + sqrt(complex(b^2 - 4a*c)))/2a
	x + λ*∇
end

function quadsteps(ξ, x::Grade{1})
	x = rej(x, ξ)
	# @show x
	for _ in 1:1
		x = quadstep(ξ, x)
		x² = abs2(x)
		# @show x²
		abs(x²) < sqrt(eps(eltype(x))) && return x
	end
	x
end

# almost a rejection, but projective and but works if A^2 = 0
rej(v, A) = v*abs2(A) + grade(involution(A)*v*reversion(A), 1)


function samplespherecomplex(ξ, n=10)
	x = randn(Multivector{signature(ξ),1}, n)
	x₀ = quadsteps.(ξ, x)
end

function with_euclidean(fn, xs::AbstractMultivector{Sig}...) where Sig
	euclidean_sig = Val(dimension(Sig))
	x̂s = GeometricAlgebra.replace_signature.(xs, euclidean_sig)
	ŷ = fn(x̂s...)
	y = GeometricAlgebra.replace_signature(ŷ, Val(Sig))
end




end
