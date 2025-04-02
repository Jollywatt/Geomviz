function send_data_to_server(data, port=PORT[])
	sock = connect(ip"127.0.0.1", port)
	binary = Pickle.stores(data)
	write(sock, binary)
	printstyled("blend: ", color=214)
	println(String(read(sock)))
end

function encode(::T) where T
	method = :($(nameof(@__MODULE__)).encode(::$T))
	@warn "Object not sent to Blender." T
end

function encode(objs::Union{Tuple,AbstractVector})
	isempty(objs) && return
	data = encode.(objs)
end

encode(a::BasisBlade) = encode(Multivector(a))

flatmap(f, a::Union{Tuple,AbstractVector}) = Iterators.flatten(flatmap(f, i) for i in a)
function flatmap(f, a)
	b = f(a)
	b isa Union{Tuple,AbstractVector} ? b : [b]
end

function encode_scene(objs)
	(
		objects=collect(flatmap(encode, objs)),
	)
end

function encode_and_send(obj)
	data = encode_scene(obj)
	!isnothing(data) && send_data_to_server(data)
	obj
end

struct Styled{T}
	obj::T
	attributes::Dict{String,Any}
	Styled(obj::T, attrs::Dict) where T = new{T}(obj, Dict(string(k) => v for (k, v) in attrs))
end
Styled(obj; kwargs...) = Styled(obj, Dict(kwargs))

function encode(s::Styled)
	data = encode(s.obj)
	if data isa Union{Tuple,AbstractVector}
		merge!.(data, Ref(s.attributes))
	else
		merge!(data, s.attributes)
	end
end

function anim()
	Dict(
		"animation"=>true,
		"frame_range"=>(0,100),
		"objects"=>[
			Dict(
				"rig_name"=>"Point",
				"location"=>Dict(
					"keyframes"=>[
						(i, (cos(2pi*t),sin(2pi*t),t))
						for (i, t) in enumerate(range(0, 1, length=100))
					]
				),
				"rig_parameters"=>Dict(
					"Radius"=>Dict(
						"keyframes"=>[(0,0), (100,1)]
					)
				),
			),
		],
	) |> send_data_to_server
end