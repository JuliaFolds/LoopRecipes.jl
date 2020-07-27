module TestSIMD

using LoopRecipes
using SparseArrays
using Test

@testset "simdpairs" begin
    xs = collect(Float64, 1:100)
    s = foldl(simdpairs(xs); init = 0.0) do acc, (_, x)
        if x isa Real
            sum(acc) + x
        else
            acc + x
        end
    end
    @test s == sum(xs)
end

@testset "simdstored" begin
    xs0 = collect(Float64, 1:100)
    xs0[1:3:end] .= 0
    xs = sparsevec(xs0)
    s = foldl(simdstored(xs); init = 0.0) do acc, (_, x)
        if x isa Real
            sum(acc) + x
        else
            acc + x
        end
    end
    @test s == sum(xs)
end

end  # module
