using .SphericalOneUp
using .SphericalOneUp: CURVATURE

using Base.ScopedValues

@testset "up, dn" begin
	for N in 1:20
		for λ in logrange(1e-4, 1e4, length=11)
			x = randn(Multivector{N,1})
			with(CURVATURE => λ) do
				@test abs2(up(SGA, x)) ≈ 1
				@test dn(up(SGA, x)) ≈ x atol=1e-6
			end
		end
	end
end

@testset "point pairs, λ=$λ" for λ in [1, 2, 10, 0.01, 1000]
	with(CURVATURE => λ) do
		for N in 1:20
			p = randn(Multivector{3,1})
			pointpair = classify(up(SGA, p))
			c = pointpair.carrier.location
			Δ = pointpair.radius*pointpair.carrier.direction
			@test p ≈ c + Δ
			@test -λ^2/p ≈ c - Δ
		end
	end
end

@testset "circles, λ=$λ" for λ in [1, 2, 10, 0.01, 1000]
	with(CURVATURE => λ) do
		for N in 1:20
			p, q = randn(Multivector{3,1}, 2)
			circle = classify(up(SGA, p)∧up(SGA, q))

			c = circle.carrier.location
			dir = circle.carrier.direction
			ρ = circle.radius

			@test abs2(p - c) ≈ ρ^2
			@test (p - c)∧dir ≈ 0 atol=sqrt(eps())
		end

	end
end