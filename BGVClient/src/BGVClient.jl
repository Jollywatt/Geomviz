module BGVClient

using Sockets
using Pickle
using ReplMaker
using REPL: LineEdit

const PORT = Ref(8888)

function send_data_to_server(data, port=PORT.x)
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

function replmode(input::String)
	x = Main.eval(Meta.parse(input))
	encode_and_send(x)
end

function valid_input_checker(prompt_state)
	str = String(take!(copy(LineEdit.buffer(prompt_state))))
	expr = Base.parse_input_line(str)
	return !Meta.isexpr(expr, :incomplete)
end

function __init__()
	if isdefined(Base, :active_repl)
		initrepl(
			replmode, 
			prompt_text="BGVClient> ",
			prompt_color=:cyan, 
			valid_input_checker=valid_input_checker,
			start_key=' ', 
			mode_name="BGVClient",
		)
	end
end


end # module BGVClient
