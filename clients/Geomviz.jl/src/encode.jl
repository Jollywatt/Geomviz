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




Pickle.save(p::Pickle.AbstractPickle, io::IO, nt::NamedTuple) = Pickle.save(p, io, Dict(string(k) => v for (k, v) in pairs(nt)))
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
	@error "$T not sent to Blender."
	@info """
	If applicable, define a method `encode(::$T)` that returns a `Rig` or a collection of `Rig`s to be sent to Blender.
	"""
	if nameof(T) in (:BasisBlade, :Multivector)
		@info "Did you forget to import GeometricAlgebraModels?"
	end
end

encode(objs::Union{Tuple,AbstractVector}) = collect(Iterators.filter(!isnothing, flatmap(encode, objs)))
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
