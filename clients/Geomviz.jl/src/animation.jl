struct Keyframes{T} <: AbstractVector{Pair{Int,T}}
	points::Vector{Pair{Int,T}}
end
Base.size(k::Keyframes) = size(k.points)
Base.getindex(k::Keyframes, i) = getindex(k.points, i)

Pickle.save(p::Pickle.AbstractPickle, io::IO, k::Keyframes) = Pickle.save(p, io, Dict("keyframes" => Tuple.(k.points)))


function add_keyframe!(anim::Keyframes, (t, new))
	(tprev, val) = last(anim.points)
	val == new && return anim
	push!(anim.points, t => new)
	return anim
end

function add_keyframe!(old::Rig, (t, new)::Pair{<:Number,Rig})
	@assert old.rig_name == old.rig_name
	objp = mergewith!(old.object_parameters, new.object_parameters) do l, r
		add_keyframe!(l::Keyframes, t => r)
	end
	rigp = mergewith!(old.rig_parameters, new.rig_parameters) do l, r
		add_keyframe!(l::Keyframes, t => r)
	end
end

identifiable(a::Rig, b::Rig) = a.rig_name == b.rig_name

function transpose_keyframes(frames::Keyframes)
	scene = Rig[]
	tstart = first(first(frames))
	for (t, objs) in frames

		used = zeros(Bool, size(scene))

		for obj in objs

			found = false
			# see if object is already in scene that can be used
			for i in eachindex(scene)
				used[i] && continue
				identifiable(scene[i], obj) || continue

				found = true
				used[i] = true

				add_keyframe!(scene[i], t => obj)
				add_keyframe!(scene[i].object_parameters["show"], t => true)

				break
			end

			# need to create new scene object
			if !found
				o = Dict{String,Any}(k => Keyframes([t => v]) for (k, v) in obj.object_parameters)
				if t > tstart
					o["show"] = Keyframes([t - 1 => false, t => true])
				else
					o["show"] = Keyframes([t => true])
				end
				r = Dict(k => Keyframes([t => v]) for (k, v) in obj.rig_parameters)
				anim_rig = Rig(obj.rig_name, o, r)

				push!(scene, anim_rig)
				push!(used, true)
			end

		end

		# mute unused scene objects
		for i in eachindex(scene)
			used[i] && continue

			add_keyframe!(scene[i].object_parameters["show"], t => false)

		end
	end
	scene
end

struct Animation

end

function animate(fn, times)
	frames = Keyframes(map(enumerate(times)) do (i, t)
		i => filter!(!isnothing, collect(flatmap(encode, fn(t))))
	end)
	scene = transpose_keyframes(frames)

	info = (
		frame_range = (first(first(frames)), first(last(frames))),
		objects = scene,
		animation = true,
	)

	send_and_receive(info)
	return
end
