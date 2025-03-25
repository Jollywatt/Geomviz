
encode(a::Multivector{3,1}) = Dict(
	"Rig"=>"Arrow Vector",
	"Vector"=>Vector(a.comps),
)

encode(a::Multivector{3,2}) = Dict(
	"Rig"=>"Circle 2-blade",
	"Normal"=>Vector(rdual(a).comps),
	"Radius"=>sqrt(sqrt(abs(a⊙a))),
)
