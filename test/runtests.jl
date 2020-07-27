module TestLoopRecipes

using Test

@testset "$file" for file in sort([
    file for file in readdir(@__DIR__) if match(r"^test_.*\.jl$", file) !== nothing
])
    if VERSION >= v"1.6.0-DEV.674" && file == "test_simd.jl"
        # Waiting for https://github.com/eschnett/SIMD.jl/pull/70
        @info "Skipping SIMD related tests in Julia $VERSION."
        continue
    end
    include(file)
end

end  # module
