using .SphericalOneUp

@testset "up, dn" begin
	for N in 1:5
		for λ in logrange(1e-5, 1e5, length=11)
			x = randn(Multivector{N,1,SVector{N,BigFloat}})
			@test dn(up(SGA, x; λ); λ) ≈ x atol=sqrt(eps())
		end
	end
end

@testset "point pairs for λ=$λ" for λ in [1, 2, 10, 0.01, 1000]
	for N in 1:5
		p = randn(Multivector{3,1})
		pointpair = classify(up(SGA, p; λ); λ)
		c = pointpair.carrier.location
		Δ = pointpair.radius*pointpair.carrier.direction
		@test p ≈ c + Δ
		# @test -λ^2/p ≈ c - Δ
	end
end