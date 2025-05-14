module LieSphereGeometry

using GeometricAlgebra
import ..Geomviz: rig, encode, geomviz, dn, normalize, classify, detect_keyframes
import ..Geomviz.Conformal: CGA

using LinearAlgebra: Diagonal, Symmetric, eigen

using ..Geomviz

export LSG

#= Defining the metric signature =#
abstract type LSG{N} end
GeometricAlgebra.dimension(::Type{LSG{Sig}}) where Sig = dimension(Sig) + 3
function GeometricAlgebra.basis_vector_square(::Type{LSG{Sig}}, i::Integer) where Sig
	(GeometricAlgebra.canonical_signature(Sig)..., +1, -1, -1)[i]
end
function GeometricAlgebra.get_basis_display_style(::Type{LSG{Sig}}) where Sig
	n = dimension(Sig)
	BasisDisplayStyle(n + 3, indices=[string.(1:n); "p"; "m"; "0"])
end



"""
	o, oo, v0 = extras(LSG{Sig})

Where `o = 2\\(vm - vp)` is the origin, `oo = vm + vp` is the point at infinity, and `v0` is the other thing.
"""
function extras(::Type{LSG{Sig}}) where Sig
	vp, vm, v0 = (basis(LSG{Sig}, 1, dimension(Sig) + i) for i in 1:3)
	o = 2\(vm - vp)
	oo = vm + vp
	o, oo, v0
end


#=
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

"""
	sphereroot(ξ, p, r, Δp, Δr)

Find values of `λ` such that ``S(p + λ Δp, r + λ Δr) ⋅ ξ = 0`` where
```math
S(p, r) = o + p + ½(p² - r²) ∞ + r e₀
```
is a Lie sphere with centre ``p ∈ ℝⁿ`` and radius ``r ∈ ℝ``.

The two roots ``λ`` are returned.
"""
function sphereroots(ξ::Multivector{LSG{Sig},1}, p::Grade{1,Sig}, r::Real, Δp::Grade{1,Sig}, Δr::Real) where Sig
	ξ₊, ξ₋, ξ0 = ξ.comps[end-2:end]
	ξo, ξ∞ = ξ₋ - ξ₊, 2\(ξ₋ + ξ₊)
	ξe = embed(Sig, ξ)

	f(p, r) = 2\(r^2 - abs2(p))ξo + p⊙ξe - ξ∞ - r*ξ0
	a = 2\(Δr^2 - abs2(Δp))ξo
	b = (ξe - ξo*p)⊙Δp + (r*ξo - ξ0)Δr
	c = f(p, r)

	iszero(a) && return true, [-c/b]

	Δ = b^2 - 4*a*c
	λ = @. (-b + [+1,-1]*sqrt(complex(Δ)))/(2a)

	# @assert all(@. abs2(f(p + λ*Δp, r + λ*Δr)) < eps())
	# @assert all(@. abs2(liesphere(p + λ*Δp, r + λ*Δr)⊙ξ) < eps())
	Δ >= 0, λ
end
sphereroots(ξ::BasisBlade, p, r, Δp, Δr) = sphereroots(Multivector(ξ), p, r, Δp, Δr)


function spheresamples(ξ::Grade{1,LSG{Sig}}, p₀, r₀; n=10) where Sig
	spheres = Tuple{Multivector{Sig,1,SVector{dimension(Sig),Float64}},Float64}[]
	for _ in 1:10_000
		Δp = randn(Multivector{Sig,1})
		Δr = randn()
		exists, λs = sphereroots(ξ, p₀, r₀, Δp, Δr)
		exists || continue
		for λ in λs
			p = p₀ + real(λ)*Δp
			r = r₀ + real(λ)*Δr
			push!(spheres, (p, r))
		end
		length(spheres) >= n && break
	end
	spheres
end

function spherewalk(ξ::Grade{1,LSG{Sig}}, p₀, r₀; Δt=1, n=10) where Sig
	ṗ = randn(Multivector{Sig,1})
	ṙ = randn()
	ps = SVector{dimension(Sig),Float64}[]
	rs = Float64[]
	for _ in 1:n
		Δp, Δr = grad(ξ, p₀, r₀)
		exists, λs = sphereroots(ξ, p₀, r₀, Δp, Δr)
		if exists
			λ = real(first(λs))
			p = p₀ + λ*Δp
			r = r₀ + λ*Δr
			push!(ps, p.comps)
			push!(rs, r)
		else
			push!(ps, fill(NaN, 3))
			push!(rs, NaN)
		end
		p₀ += ṗ*Δt
		r₀ += ṙ*Δt
	end
	# @assert length(ps) == length(rs) == 2n
	ps, rs
end


function liesphere(p::Grade{1,Sig}, r) where Sig
	o, oo, v0 = extras(LSG{Sig})
	o + embed(LSG{Sig}, p) + 2\(abs2(p) - r^2)oo + r*v0
end

function sphererig(p, r)
	if iszero(r)
		rig("Point", location=p)
	else
		rig("Sphere", location=p, "Radius"=>abs(r))
	end
end

function spaz(ξ::Grade{1,LSG{3}})
	frames = 10
	objects_per_frame = 5
	nobjs = frames*objects_per_frame
	p₀ = randn(Multivector{3,1})
	r₀ = randn()
	objs = map(spheresamples(Multivector(ξ), p₀, r₀; n=nobjs)) do (p, r)
		if iszero(r)
			rig("Point", location=p)
		else
			rig("Sphere", location=p, "Radius"=>abs(r))
		end
	end
	windows = eachcol(reshape(objs, objects_per_frame, frames))
	kfs = Geomviz.detect_keyframes(eachindex(windows), collect(windows))
	(
		animation=true,
		frame_range=(firstindex(windows), lastindex(windows)),
		objects=kfs
	) |> Geomviz.send_to_server
end

function geomviz_walk(ξ::Grade{1,LSG{Sig}}) where Sig
	nframes = 200
	nobjs = 3

	objs = map(1:nobjs) do _
		p₀ = randn(Multivector{Sig,1})
		r₀ = randn()
		ps, rs = spherewalk(ξ, p₀, r₀; n=nframes, Δt=0.01)

		for (p, r) in zip(ps, rs)
			# @show abs(liesphere(Multivector{Sig,1}(p), r)⊙ξ)
		end
		rig("Sphere",
			location=Geomviz.Keyframes(1:nframes .=> ps),
			"Radius"=>Geomviz.Keyframes(1:nframes .=> abs.(rs)),
		)
	end

	(
		animation=true,
		frame_range=(1, nframes),
		objects=objs
	) |> Geomviz.send_to_server
end

function grad(ξ::Grade{1,LSG{Sig}}, p, r) where Sig
	ξ₊, ξ₋, ξ0 = Multivector(ξ).comps[end-2:end]
	ξo, ξ∞ = ξ₋ - ξ₊, 2\(ξ₋ + ξ₊)
	ξe = embed(Sig, ξ)
	(ξe - ξo*p, r*ξo - ξ0)
end

=#

macro assertsmall(lhs, tol)
	message = sprint(print, lhs)
	quote
		let x = $lhs
			@assert abs(x) <= $tol "$($message) = $x > $($tol)"
		end
	end |> esc
end

"""
	root_of_diagonal_quadratic_form(λ, [z])

Find a vector `z₀` near to the initial `z` which satisfies
```
z₀'D*z₀ == sum(@. λ*z₀^2) ≈ 0
```
where `D = Diagonal(λ)` is a diagonal matrix with main diagonal `λ::AbstractVector`.

If `z` is `nothing`, find a random root near `randn(length(λ))`.
"""
root_of_diagonal_quadratic_form(λ::AbstractVector, ::Nothing) = root_of_diagonal_quadratic_form(λ, randn(length(λ)))
function root_of_diagonal_quadratic_form(λ::AbstractVector, z::AbstractVector{T}) where T
	if all(>(0), λ) || all(<(0), λ)
		return zero(z)
	end

	pos = λ .> eps(T)
	neg = λ .< -eps(T)

	z[pos] /= sqrt(sum(abs2, z[pos]))
	z[neg] /= sqrt(sum(abs2, z[neg]))
	z[@. !pos & !neg]

	nonzero = pos .|| neg
	z[nonzero] ./= sqrt.(abs.(λ[nonzero]))

	return z
end

"""
	project_to_ipns(ξ::Multivector{LSG{Sig},K}, z::Vector)

Find a ``1``-vector `x::Multivector{LSG{Sig},1}` in the
_inner product null space_ of the `k`-blade `ξ` such that
```
x⋅x == x⋅ξ == 0
```
is (approximately) satisfied.

The vector `x` is parametrised by the _latent vector_ `z`,
which should have `length(z) == dimension(ξ) - k`.
For a fixed blade `ξ`, similar values of `z` give similar results `x`.
"""
project_to_ipns(ξ::Multivector, z::AbstractVector) = project_to_ipns(ξ, reshape(z, :, 1))

"""
	project_to_ipns(ξ::Multivector{LSG{Sig},K}, Z::Matrix)

Find a vector of ``1``-vectors `x`, one for each column in the latent matrix `Z`.
"""
function project_to_ipns(ξ::Multivector{LSG{Sig},K}, Z::AbstractMatrix) where {Sig,K}
	@assert length(K) == 1 "must be a homogeneous blade, got K = $K"
	zdim = dimension(ξ) - grade(ξ)
	@assert size(Z, 1) == zdim "latent vectors must have length $zdim"

	A = stack(ξᵢ.comps for ξᵢ in GeometricAlgebra.fastfactor(hodgedual(ξ)))

	η = Diagonal(collect(GeometricAlgebra.canonical_signature(LSG{Sig})))
	B = Symmetric(A'*η*A)
	λ, U = eigen(B)


	Z₀ = mapslices(Z, dims=1) do z
		root_of_diagonal_quadratic_form(λ, z)
	end

	Multivector{LSG{Sig},1}.(eachcol(A*U*Z₀))
end
project_to_ipns(ξ::BasisBlade, z) = project_to_ipns(Multivector(ξ), z)

function geomviz(ξ::AbstractMultivector{LSG{Sig}}) where Sig
	nframes = 100
	tscale = 1
	zdim = dimension(ξ) - grade(ξ)

	# create a bunch of random time-varying latent vectors, z
	ts = range(-π/2, π/2, length=nframes)
	vectors = randn(Multivector{zdim,1}, 1, 10)
	if zdim >= 2
		bivectors = randn(Multivector{zdim,2}, 1, 1, 10)
		@. bivectors /= sqrt(abs(abs2(bivectors)))

		# axes: (t, vector, bivector)
		zt = sandwich_prod.(exp.(bivectors.*ts), vectors)
	else
		zt = vectors.*ts
		zt = reshape(zt, size(zt)..., 1)
	end

	Z = reinterpret(Float64, reshape(zt, 1, :))

	# get Lie vectors parametrised by latent vectors
	xs = project_to_ipns(ξ, Z)

	# convert Lie vectors to Sphere/Plane rigs
	rigs = reshape(geomviz.(classify_null.(xs)), nframes, :)

	anim = detect_keyframes(range(1, length=nframes, step=tscale), eachslice(rigs, dims=1))

	(
		animation=true,
		frame_range=(1, tscale*nframes),
		objects=anim
	) |> Geomviz.send_to_server
end

struct Plane{N}
	normal::Multivector{N,1,SVector{N,Float64}}
	distance::Float64
end

struct Sphere{N}
	location::Multivector{N,1,SVector{N,Float64}}
	radius::Float64
end

geomviz(Π::Plane) = rig("Plane", location=Π.normal*Π.distance/sqrt(abs2(Π.normal)), "Normal"=>Π.normal)
function geomviz(S::Sphere)
	if abs(S.radius) < 1e-3
		rig("Point", location=S.location)
	else
		rig("Sphere", location=S.location, "Radius"=>S.radius, "Holes"=>(S.radius < 0))
	end
end

function classify_null(ξ::Multivector{LSG{Sig},1}) where Sig
	ξ² = abs2(ξ)
	@assert abs(ξ²) < sqrt(eps()) "not a null vector; has square $ξ²"

	ξ₊, ξ₋, ξ0 = Multivector(ξ).comps[end-2:end]
	ξo, ξ∞ = ξ₋ - ξ₊, 2\(ξ₋ + ξ₊)
	ξe = embed(Sig, ξ)

	if abs(ξo) < eps()
		if abs(ξ0) < eps()
			# point at infinity
			missing
		else
			# plane
			d = ξ∞/ξ0
			n̂ = ξe/ξ0
			Plane(n̂, d)
		end
	else
		# sphere
		p = ξe/ξo
		r = ξ0/ξo
		Sphere(p, r)
	end
end

end
