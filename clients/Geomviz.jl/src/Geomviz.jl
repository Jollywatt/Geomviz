module Geomviz

using Sockets
using Pickle
using ReplMaker
using REPL: LineEdit
using GeometricAlgebra

export encode, PORT, Styled, animate
export up, dn, unembed, normalize, classify
export Projective, PGA
export Conformal, CGA

function dn end
function normalize end
function classify end

normalize(a::BasisBlade) = normalize(Multivector(a))

include("client.jl")
include("animation.jl")
include("models/vga.jl")
include("models/pga.jl")
include("models/cga.jl")

import .Projective: PGA
import .Conformal: CGA

up(T::Type{<:Projective.ProjectiveSignature}, a::AbstractMultivector) = Projective.up(T, a)
up(::Type{<:Conformal.CGA}, a::AbstractMultivector) = Conformal.up(a)
up(T::Type, comps::Number...) = up(T, Multivector{length(comps),1}(comps))

up(v::AbstractMultivector{<:CGA}) = Conformal.up(unembed(v))

for T in [BasisBlade, Multivector]
	@eval GeometricAlgebra.embed(::Type{CGA}, a::$T) = Conformal.embed(Multivector(a))
end


"""
	unembed(a::Multivector)

The part of a multivector lying in the base space `Sig` if the multivector is
embedded in higher space such as `CGA{Sig}`.
"""
unembed(a::AbstractMultivector{<:CGA{Sig}}) where Sig = GeometricAlgebra.embed(Sig, a)

#= blend repl mode =#

function replmode(input::String)
	isdefined(Main, :Revise) && Main.eval(:(Revise.revise()))
	x = Main.eval(Meta.parse(input))
	data = encode_many(x)
	!isnothing(data) && send_to_server(data)
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
