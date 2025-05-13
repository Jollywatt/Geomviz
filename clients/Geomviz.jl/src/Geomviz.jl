module Geomviz

using Sockets
using Pickle
using ReplMaker
using REPL: LineEdit
using GeometricAlgebra

export geomviz, encode, PORT, Styled, animate
export up, dn, unembed, normalize, classify
export Projective, PGA
export Conformal, CGA
export SphericalOneUp, SGA
export LieSphereGeometry, LSG

function dn end
function normalize end
function classify end
function geomviz end

Base.abs2(a::AbstractMultivector) = scalar_prod(a, a)
normalize(a::AbstractMultivector) = a/sqrt(abs(abs2(a)))

include("client.jl")
include("animation.jl")
include("models/vga.jl")
include("models/pga.jl")
include("models/cga.jl")
include("models/sga.jl")
include("models/lsg.jl")

import .Projective: PGA
import .Conformal: CGA
import .SphericalOneUp: SGA
import .LieSphereGeometry: LSG

up(T::Type{<:Projective.ProjectiveSignature}, a::AbstractMultivector) = Projective.up(T, a)
up(::Type{<:Conformal.CGA}, a::AbstractMultivector) = Conformal.up(a)
up(::Type{<:SphericalOneUp.SGA}, a::AbstractMultivector; kw...) = SphericalOneUp.up(a; kw...)
up(T::Type, comps::Number...) = up(T, Multivector{length(comps),1}(comps))

up(v::AbstractMultivector{<:CGA}) = Conformal.up(unembed(v))
up(v::AbstractMultivector{<:SGA}) = SphericalOneUp.up(unembed(v))

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

geomviz(::Nothing) = nothing
function geomviz(x)
	data = (objects=encode([x]),)
	send_to_server(data)
end

function replmode(input::String)
	if startswith(strip(input), '?')
		print("""
		This is the Geomviz REPL mode.

		Input evaluated in this mode is passed to `Geomviz.geomviz()`.
		""")
		return
	end

	isdefined(Main, :Revise) && Main.eval(:(Revise.revise()))
	x = Main.eval(Meta.parse(input))
	geomviz(x)
	Meta.quot(x)
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
			prompt_text="geomviz> ",
			prompt_color=214,
			valid_input_checker=valid_input_checker,
			start_key=' ',
			mode_name="Geomviz",
			startup_text=false,
		)
		print("Press space to enter the ")
		printstyled("geomviz>", color=214)
		print(" REPL mode.")
	end
end

end # module Geomviz
