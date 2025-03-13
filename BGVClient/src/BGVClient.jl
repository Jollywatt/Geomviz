module BGVClient

using Sockets
using Pickle
using ReplMaker
using REPL: LineEdit

using GeometricAlgebra
using GeometricAlgebra: replace_signature

export encode

export PGA, Projective
export CGA, up

include("client.jl")
include("algebras.jl")
include("encode.jl")

const PORT = Ref(8888)

function replmode(input::String)
	isdefined(Main, :Revise) && Main.eval(:(Revise.revise()))
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
			prompt_text="blend> ",
			prompt_color=214,
			valid_input_checker=valid_input_checker,
			start_key=' ',
			mode_name="BGVClient",
		)
	end
end

end # module BGVClient
