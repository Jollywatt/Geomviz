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
include("vga.jl")
include("pga.jl")
include("cga.jl")
include("spherical-1up.jl")
include("animation.jl")

import .Projective: PGA
import .Conformal: CGA
import .SphericalOneUp: SGA

up(T::Type{<:Projective.ProjectiveSignature}, a::AbstractMultivector) = Projective.up(T, a)
up(::Type{<:Conformal.CGA}, a::AbstractMultivector) = Conformal.up(a)
up(::Type{SphericalOneUp.SGA}, a::AbstractMultivector) = SphericalOneUp.up(a)
up(T::Type, comps::Number...) = up(T, Multivector{length(comps),1}(comps))

GeometricAlgebra.embed(::Type{CGA}, a::Multivector) = Conformal.embed(a)
GeometricAlgebra.embed(::Type{SGA}, a::Multivector) = SphericalOneUp.embed(a)

"""
	unembed(a::Multivector)

The part of a multivector lying in the base space `Sig` if the multivector is
embedded in higher space such as `CGA{Sig}` or `SGA{Sig}`.
"""
unembed(a::Multivector{<:Union{CGA{Sig},SGA{Sig}}}) where Sig = GeometricAlgebra.embed(Sig, a)

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
