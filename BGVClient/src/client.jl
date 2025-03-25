function send_data_to_server(data, port=PORT[])
	sock = connect(ip"127.0.0.1", port)
	binary = Pickle.stores(data)
	write(sock, binary)
end

function encode(::T) where T
	method = :($(nameof(@__MODULE__)).encode(::$T))
	@warn "Object not sent to Blender: no method $method."
end

function encode(objs::Union{Tuple,AbstractVector})
	isempty(objs) && return
	data = encode.(Iterators.flatten(objs))
end

encode(a::BasisBlade) = encode(Multivector(a))

encode_scene(obj) = encode_scene([obj])
function encode_scene(objs::Union{Tuple,AbstractVector})
	wrap(a) = a isa AbstractVector ? a : [a]
	objs = [wrap(encode(obj)) for obj in objs if !isnothing(obj)]
	(scene=collect(Iterators.flatten(objs)),)
end

function encode_and_send(obj)
	data = encode_scene(obj)
	!isnothing(data) && send_data_to_server(data)
	obj
end

