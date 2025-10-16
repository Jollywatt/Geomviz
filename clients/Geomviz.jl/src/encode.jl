struct Rig
	rig_name::String
	object_parameters::Dict{String,Any}
	rig_parameters::Dict{String,Any}
end

function Rig(rig_name::String, rig_parameters::Pair{String}...; object_parameters...)
	object_parameters = Dict(string(k) => v for (k, v) in pairs(object_parameters))
	Rig(rig_name, object_parameters, Dict{String,Any}(rig_parameters))
end

function Base.show(io::IO, mime::MIME"text/plain", rig::Rig)
	print(io, typeof(rig), ":")
	ioc = IOContext(io, :limit=>true)
	for field in fieldnames(typeof(rig))
		value = getfield(rig, field)
		if value isa Dict
			print(io, "\n $field: ")
			show(ioc, mime, value)
		else
			print(io, "\n $field: ", repr(value))
		end
	end
end


struct Styled{T}
	obj::T
	object_parameters::Dict{String,Any}
	rig_parameters::Dict{String,Any}
end

function Styled(obj, rig_parameters::Pair{String}...; object_parameters...)
	object_parameters = Dict{String,Any}(string(k) => v for (k, v) in object_parameters)
	Styled(obj, object_parameters, Dict{String,Any}(rig_parameters))
end




Pickle.List(a::GeometricAlgebra.SingletonVector) = Pickle.List(collect(a))
Pickle.List(a::GeometricAlgebra.StaticVector) = Pickle.List(collect(a))
Pickle.save(p::Pickle.AbstractPickle, io::IO, nt::NamedTuple) = Pickle.save(p, io, Dict(string(k) => v for (k, v) in pairs(nt)))
Pickle.save(p::Pickle.AbstractPickle, io::IO, mv::Grade{1}) = Pickle.save(p, io, Multivector(mv).comps)
function Pickle.save(p::Pickle.AbstractPickle, io::IO, rig::Rig)
	d = Dict(
		"rig_name"=>rig.rig_name,
		"rig_parameters"=>rig.rig_parameters,
		rig.object_parameters...,
	)
	Pickle.save(p, io, d)
end



flatmap(f, a::Union{Tuple,AbstractVector}) = Iterators.flatten(flatmap(f, i) for i in a)
function flatmap(f, a)
	b = f(a)
	b isa Union{Tuple,AbstractVector} ? b : (b,)
end


function encode(::T) where T
	@warn "Object not sent to Blender." T
end

encode(objs::Union{Tuple,AbstractVector}) = collect(flatmap(encode, objs))
encode(objs...) = encode(objs)

encode(rig::Rig) = rig

function encode(s::Styled)
	things = encode(s.obj)
	if things isa Union{Tuple,AbstractVector}
		for rig in things
			merge!(rig.object_parameters, s.object_parameters)
			merge!(rig.rig_parameters, s.rig_parameters)
		end
	elseif things isa Rig
		rig = things
		merge!(rig.object_parameters, s.object_parameters)
		merge!(rig.rig_parameters, s.rig_parameters)
	else
		throw(ArgumentError("What's this? $things"))
	end

	things
end

