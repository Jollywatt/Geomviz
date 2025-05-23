using Test
using GeometricAlgebra
using Geomviz

alltests() = relpath.(filter(readdir(dirname(@__FILE__), join=true)) do file
	endswith(file, ".jl") && file != @__FILE__
end, pwd())

function test(files=alltests())
	@testset "$file" for file in files
		include(file)
	end
	nothing
end
