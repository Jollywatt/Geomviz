function send_data_to_server(data, port=PORT[])
	sock = connect(ip"127.0.0.1", port)
	binary = Pickle.stores(data)
	write(sock, binary)
end


function encode(::T) where T
	method = :($(nameof(@__MODULE__)).encode(::$T))
	@warn "Object not sent to BGV server: no method $method."
end

function encode(objs::Union{Tuple,AbstractVector})
	isempty(objs) && return
	data = encode.(objs)
	mergewith(vcat, data...)
end

function encode_and_send(obj)
	data = encode(obj)
	if !isnothing(data)
		send_data_to_server(data)
	end
	obj
end

