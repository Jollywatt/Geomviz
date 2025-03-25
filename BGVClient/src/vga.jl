
encode(a::Multivector{3,1}) = Dict(
	"Arrow Vector" => [Dict("Vector"=>Vector(a.comps))]
)

encode(a::Multivector{3,1}) = (rig="Arrow Vector", )

encode(a::Multivector{3,2}) = Dict(
	"Circle 2-blade" => [Dict(
		"Normal"=>Vector(rdual(a).comps),
		"Radius"=>sqrt(sqrt(abs(a⊙a))),
	)]
)
