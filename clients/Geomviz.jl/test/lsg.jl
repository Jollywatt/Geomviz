using .LieSphereGeometry
using .LieSphereGeometry: root_of_diagonal_quadratic_form

using LinearAlgebra: Diagonal

@testset "roots of diagonal quadratic form" begin
	for λ in [
		[1, 1],
		[1, 2, -1],
		[0, 1, 1],
		[0, 1, -1],
		[0, 0, 2, 2, -2],
		[1, -1, 100],
		[1, eps(), 1],
	]
		for _ in 1:100
			z = rand(length(λ))
			z₀ = root_of_diagonal_quadratic_form(λ, z)
			@test abs(z₀'Diagonal(λ)*z₀) < 10eps()
			@test all(isfinite, z)
		end
	end
end