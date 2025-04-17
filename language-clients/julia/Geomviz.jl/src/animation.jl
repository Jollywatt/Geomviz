class(a::Dict) = a["rig_name"]
function canbeidentified(a::Dict, b::Dict)
	a["rig_name"] == b["rig_name"] && keys(a) == keys(b)
end

function animate(fn, ts::AbstractVector)
	frames = map(ts) do t
		flatmap(encode, fn(t))
	end
	(
		animation=true,
		frame_range=(firstindex(ts), lastindex(ts)),
		objects=detect_keyframes(eachindex(ts), frames),
	) |> send_to_server
end

function detect_keyframes(ts, frames)
	zipped = Dict[]
	tprev = 0
	for (t, objs) in zip(ts, frames)

		used = zeros(Bool, length(zipped)) # which persistent objects are used this frame
		for obj in objs
			found = false
			for i in eachindex(zipped)
				used[i] && continue
				if canbeidentified(zipped[i], obj)

					zipped[i] = merge_keyframes(tprev => zipped[i], t => obj)
					used[i] = true
					found = true
					break
				end
			end

			if !found
				push!(zipped, obj)
				push!(used, true)
			end


		end
		tprev = t
	end
	zipped
end

struct Keyframes{T} <: AbstractVector{Pair{Int,T}}
	points::Vector{Pair{Int,T}}
end
Base.size(k::Keyframes) = size(k.points)
Base.getindex(k::Keyframes, i) = getindex(k.points, i)

# merge_keyframes(l, r, t1, t2) = l == r ? l : Keyframes([t1 => l, t2 => r])
# merge_keyframes(l::Keyframes, r, t1, t2) = Keyframes([l.points; t2 => r])
# merge_keyframes(l::Dict, r::Dict, t1, t2) = Dict(k => merge_keyframes(l[k], r[k], t1, t2) for k in keys(l))

merge_keyframes((t1, obj1)::Pair{Int}, (t2, obj2)::Pair{Int}) = obj1 == obj2 ? obj1 : Keyframes([t1 => obj1; t2 => obj2])
merge_keyframes((t1, obj1)::Pair{Int,<:Keyframes}, (t2, obj2)::Pair{Int}) = Keyframes([obj1.points; t2 => obj2])
function merge_keyframes((t1, obj1)::Pair{Int,<:Dict}, (t2, obj2)::Pair{Int,<:Dict})
	@assert keys(obj1) == keys(obj2)
	Dict(k => merge_keyframes(t1 => obj1[k], t2 => obj2[k]) for k in keys(obj1))
end

Pickle.save(p::Pickle.AbstractPickle, io::IO, k::Keyframes) = Pickle.save(p, io, Dict("keyframes" => Tuple.(k.points)))

