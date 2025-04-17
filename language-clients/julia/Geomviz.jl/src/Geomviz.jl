module Geomviz

using Sockets
using Pickle
using ReplMaker
using REPL: LineEdit
using GeometricAlgebra

export encode, PORT, Styled, animate
export up, dn, unembed
export Projective, PGA
export Conformal, CGA
export SphericalOneUp, SGA

function dn end
function normalize end

normalize(a::BasisBlade) = normalize(Multivector(a))

include("client.jl")
include("animation.jl")
include("models/vga.jl")
include("models/pga.jl")
include("models/cga.jl")
include("models/spherical-1up.jl")

import .Projective: PGA
import .Conformal: CGA
import .SphericalOneUp: SGA

up(T::Type{<:Projective.ProjectiveSignature}, a::AbstractMultivector) = Projective.up(T, a)
up(::Type{<:Conformal.CGA}, a::AbstractMultivector) = Conformal.up(a)
up(::Type{SphericalOneUp.SGA}, a::AbstractMultivector) = SphericalOneUp.up(a)
up(T::Type, comps::Number...) = up(T, Multivector{length(comps),1}(comps))

up(v::Grade{1,CGA{3}}) = Conformal.up(unembed(v))
up(v::Grade{1,SGA{3}}) = SphericalOneUp.up(unembed(v))

for (Sig, mod) in [Type{CGA} => Conformal, Type{SGA} => SphericalOneUp], T in [BasisBlade, Multivector]
	@eval GeometricAlgebra.embed(::$Sig, a::$T) = $mod.embed(Multivector(a))
end

"""
	unembed(a::Multivector)

The part of a multivector lying in the base space `Sig` if the multivector is
embedded in higher space such as `CGA{Sig}` or `SGA{Sig}`.
"""
unembed(a::AbstractMultivector{<:Union{CGA{Sig},SGA{Sig}}}) where Sig = GeometricAlgebra.embed(Sig, a)

#= blend repl mode =#

function replmode(input::String)
	isdefined(Main, :Revise) && Main.eval(:(Revise.revise()))
	x = Main.eval(Meta.parse(input))
	data = encode_scene(x)
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
