module Geomviz

using Sockets
using Pickle
using ReplMaker
using REPL: LineEdit
using GeometricAlgebra

export geomviz, encode, PORT, Styled, animate
export Rig, Keyframes

include("client.jl")
include("animation.jl")
include("models/vga.jl")
include("models/cga.jl")

#= blend repl mode =#

geomviz(::Nothing) = nothing
function geomviz(x)
	data = (objects=encode([x]),)
	send_to_server(data)
end

encode(x::BasisBlade) = encode(Multivector(x))

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
	x
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
