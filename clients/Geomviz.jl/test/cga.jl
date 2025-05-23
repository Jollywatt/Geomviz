using Geomviz.Conformal

@testset "blade standardisation" begin

	@testset for dim in 0:4
		o, oo = origin(CGA{dim}), infinity(CGA{dim})

		@testset for k in 0:dim
			for _ in 1:100
				E = k > 0 ? embed(CGA, wedge(randn(Multivector{dim,1}, k)...)) : randn()
				p = randn(Multivector{dim,1})
				r² = randn()

				dir = E∧oo
				flat = translate(p, o∧E∧oo)
				dualflat = translate(p, E)
				round = translate(p, (o + 2\r²*oo)∧E)

				@test Multivector(standardform(dir)) ≈ dir
				@test Multivector(standardform(flat)) ≈ flat
				@test Multivector(standardform(dualflat)) ≈ dualflat
				@test Multivector(standardform(round)) ≈ round
			end
		end
	end
	
end