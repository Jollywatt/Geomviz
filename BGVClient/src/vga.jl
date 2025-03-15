
encode(a::Multivector{3,1}) = Dict(
	"Arrow Vector" => [(; Vector=Vector(a.comps))]
)

encode(a::Multivector{3,2}) = Dict(
	"Circle 2-blade" => [Vector(rdual(a).comps)]
)
