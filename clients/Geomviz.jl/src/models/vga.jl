#= Vector/Vanilla Geometric Algebra =#

encode(a::Multivector{3,1}) = rig(
	"Arrow Vector",
	location=(0,0,0),
	"Vector"=>Vector(a.comps),
)

encode(a::Multivector{3,2}) = rig(
	"Spear Disk",
	location=(0,0,0),
	"Normal"=>Vector(rdual(a).comps),
	"Radius"=>sqrt(sqrt(abs(a⊙a))),
)
