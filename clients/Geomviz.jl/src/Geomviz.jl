module Geomviz

using Sockets
using Pickle
using ReplMaker
using REPL: LineEdit

export geomviz, encode, Styled, animate
export Rig, Keyframes

include("encode.jl")
include("animation.jl")


const PORT = Ref(8888)

function send_and_receive(data, port=PORT[])
	local sock
	try
		sock = connect(ip"127.0.0.1", port)
	catch err
		if err isa Base.IOError
			@error """
				Could not connect to Geomviz server.
				""" err port
			@info """
				Is the Geomviz server in Blender listening on port $port?
				If listening on another port, configure with `Geomviz.PORT[] = ...`"
				"""
			return
		else
			rethrow()
		end
	end

	binary = Pickle.stores(data)
	write(sock, binary)
	closewrite(sock)
	Timer(1) do _
		if isopen(sock)
			@warn "Received no response from Geomviz server: timed out"
			close(sock)
		end
	end
	response = read(sock, String)
	close(sock)

	message = chopprefix(response, r"(Error|Success):\s*")
	if startswith(response, "Error:")
		@error "from Geomviz server:\n$message"
	elseif startswith(response, "Success:")
		@info "$message"
		return true
	else
		@warn "Geomviz server response:" response
	end
end

"""
	geomviz(x)

Visualise `x` in Blender.

The object is serialised with `encode(x)` and sent to the Blender server on port `Geomviz.PORT`.
Methods should be added to `encode` to support new object types.

Note that the `geomviz>` REPL mode may be activated by typing a space at the start of the standard REPL.
"""
function geomviz end

geomviz(::Nothing) = nothing
function geomviz(x)
	objects = encode((x,))
	isempty(objects) && return
	data = (objects=objects,)
	success = send_and_receive(data)
	success == true || return nothing
	x
end

#= blend repl mode =#


function replmode(input::String)
	if startswith(strip(input), '?')
		print("""
		This is the Geomviz REPL mode.

		Input evaluated in this mode is passed to `Geomviz.geomviz()`, which sends \
		objects to be visualised via the Geomviz Blender add-on.
		""")
		return
	end

	isdefined(Main, :Revise) && Main.eval(:(Revise.revise()))
	x = Main.eval(Meta.parse(input))
	geomviz(x)
end

function valid_input_checker(prompt_state)
	str = String(take!(copy(LineEdit.buffer(prompt_state))))
	expr = Base.parse_input_line(str)
	return !Meta.isexpr(expr, :incomplete)
end

function __init__()
	if isdefined(Base, :active_repl)
		initrepl(
			Meta.quot∘replmode,
			prompt_text="geomviz> ",
			prompt_color=214,
			valid_input_checker=valid_input_checker,
			start_key=' ',
			mode_name="Geomviz",
			startup_text=false,
		)
		print("Press space to enter the ")
		printstyled("geomviz>", color=214)
		print(" REPL mode (then enter `?` for help).")
	end
end


end # module Geomviz
