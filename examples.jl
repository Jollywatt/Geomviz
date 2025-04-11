using GeometricAlgebra, Geomviz
using Combinatorics: powerset

function anim_lambda()
	x = randn(Multivector{3,1}, 5)
	t = @. exp(1 + 2.5sin($range(0, 2π, length=300)))

	animate(t) do λ
		SphericalOneUp.CURVATURE[] = λ

		X = up.(SGA, x)
		L = [a∧b for (a, b) in powerset(X, 2, 2)]

		encode((
			Styled(X, color=(0,0,1,1)),
			Styled(L, "Circle resolution"=>1024),
		))
	end

end

function anim_toridal_rotor()
	o, oo = Conformal.origin(CGA{3}), Conformal.infinity(CGA{3})

	x = up.(CGA, randn(Multivector{3,1}, 50))

	s = wedge(rand(x, 3)...)
	S = wedge(rand(x, 3)...)

	p = up.(CGA, randn(Multivector{3,1}, 3))
	c = wedge(p...)

	c /= sqrt(c⊙c)

	R(t) = exp(t*hodgedual(c))
	animate(range(0, π, length=300)) do t
		Rt = R(t)
		y = sandwich_prod.(Rt, x)
		[
			Styled(c, color=(1,0.5,0,1))
			y
			sandwich_prod(Rt, s)
			sandwich_prod(Rt, S)
		]
	end

end

function anim_rotor_fit()

	N = 10
	points = randn(Multivector{3,1}, N)
	target_rotor = exp(10*randn(Multivector{3,2}))
	points′ = @. sandwich_prod(target_rotor, points)

	function loss(B)
		N\sum(
			scalar((sandwich_prod(exp(B), points[i]) - points′[i])^2)
			for i in 1:N
		)
	end

	B = randn(Multivector{3,2}) # random initial guess
	rule = Mooncake.build_rrule(loss, B)

	function ∇loss_auto(B)
		value, grad = Mooncake.value_and_gradient!!(rule, loss, B)
		typeof(B)(grad[2].fields.comps.fields.data)
	end


	stepsize = 1e-3
	noise = 1e-3
	animate(range(0, 300)) do frame
		for i in 1:15
			δB = -stepsize*∇loss_auto(B)
			l = loss(B)
			B += δB + l*noise*randn(typeof(B))
		end
		Styled(points, color=(1,0.1,0,1)), sandwich_prod.(exp(B), points)
	end
end