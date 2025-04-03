class(a::Dict) = a[:kind]


function animate(fn, ts)
	frames = map(fn, ts)

	zipped = []
	for frame in frames
		# objs = flatmap(encode, frame)
		objs = frame
		used = zeros(Bool, length(zipped)) # which persistent objects are used this frame
		for obj in objs
			found = false
			for i in eachindex(zipped)
				used[i] && continue
				if class(zipped[i]) == class(obj)
					zipped[i] = mergewith(zipped[i], obj) do l, r
						[l; r]
					end
					used[i] = true
					found = true
				end
			end

			if !found
				push!(zipped, obj)
			end


		end
	end
	zipped
end



# [
# 	{a: 1, b: (1, 0), c: false},
# 	{a: 1, b: (1.2, 0), c: false},
# 	{a: 1, b: (1.55, 0), c: false},
# 	{a: 1, b: (1.5, 0), c: true},
# 	{a: 1, b: (1.3, 0), c: true},
# ]

# {
# 	a: 1,
# 	b: {
# 		keyframes: [
# 			(1, (1, 0))
# 			(2, (1.2, 0))
# 			(3, (1.55, 0))
# 			(4, (1.5, 0))
# 			(5, (1.3, 0))
# 		]
# 	},
# 	c: {
# 		(1, false),
# 		(4, true)
# 	}
# }


# [
# 	[{type: 1, data: 'A1'}, {type: 2, data: 'B1'}, {type: 1, data: 'C1'}],
# 	[{type: 1, data: 'A2'}, {type: 2, data: 'B2'}, {type: 1, data: 'C2'}],
# 	[{type: 1, data: 'A2'}, {type: 2, data: 'B2'}],
# 	[{type: 2, data: 'B2'}, {type: 1, data: 'A2'}],
# ]

# [
# ]