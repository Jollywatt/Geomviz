const PORT = Ref(8888)

# Pickle.List(a::GeometricAlgebra.Multivector{Sig,1}) where Sig = Pickle.List(collect(a.comps))
Pickle.List(a::GeometricAlgebra.SingletonVector) = Pickle.List(collect(a))
Pickle.List(a::GeometricAlgebra.StaticVector) = Pickle.List(collect(a))
function Pickle.save(p::Pickle.AbstractPickle, io::IO, nt::NamedTuple)
	Pickle.save(p, io, Dict(string(k) => v for (k, v) in pairs(nt)))
end
function Pickle.save(p::Pickle.AbstractPickle, io::IO, mv::Multivector{Sig,1}) where Sig
	Pickle.save(p, io, mv.comps)
end

function send_to_server(data, port=PORT[], showresponse=true)
    sock = connect(ip"127.0.0.1", port)
	binary = Pickle.stores(data)
	write(sock, binary)
	close(sock)
end

function encode(::T) where T
	method = :($(nameof(@__MODULE__)).encode(::$T))
	@warn "Object not sent to Blender." T
end

encode(encoded::Dict{String}) = encoded

function encode(objs::Union{Tuple,AbstractVector})
	isempty(objs) && return
	data = encode.(objs)
end

encode(a::BasisBlade) = encode(Multivector(a))

flatmap(f, a::Union{Tuple,AbstractVector}) = Iterators.flatten(flatmap(f, i) for i in a)
function flatmap(f, a)
	b = f(a)
	b isa Union{Tuple,AbstractVector} ? b : [b]
end

function encode_scene(objs)
	(
		objects=collect(flatmap(encode, objs)),
	)
end

struct Styled{T}
	obj::T
	rig_parameters::Dict{String,Any}
	attributes::Dict{String,Any}
end
function Styled(obj, rig_parameters::Pair{String}...; attributes...)
	attributes = Dict{String,Any}(string(k) => v for (k, v) in attributes)
	Styled(obj, Dict{String,Any}(rig_parameters), attributes)
end

function encode(s::Styled)
	data = encode(s.obj)
	if data isa Union{Tuple,AbstractVector}
		for thing in data
			merge!(thing, s.attributes)
			merge!(thing["rig_parameters"], s.rig_parameters)
		end
	elseif data isa Dict
		merge!(data, s.attributes)
		merge!(data["rig_parameters"], s.rig_parameters)
	else
		throw(Exception("What's this?", data))
	end

	data
end

function rig(rig_name, rig_parameters::Pair{String}...; object_parameters...)
	object_parameters = [string(k) => v for (k, v) in pairs(object_parameters)]
	Dict{String,Any}(
		"rig_name"=>rig_name,
		"rig_parameters"=>Dict{String,Any}(rig_parameters),
		object_parameters...,
	)
end
