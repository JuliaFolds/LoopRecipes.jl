module TestUnroll

using LoopRecipes
using MicroCollections: EmptyVector
using Test
using Transducers: Empty, Map, ReduceIf, append!!, right

@testset "nonempty" begin
    @testset for n in 1:20, f in 1:4
        @test sum(unroll(f, 1:n)) == sum(1:n)
        @test sum(unroll(f, copy([1:n 1:n]')')) == 2 * sum(1:n)
        @test collect(Map(identity), unroll(f, 1:n)) == 1:n
        @test collect(Map(identity), unroll(f, copy([1:n 1:n]')')) == [1:n; 1:n]
    end
end

@testset "with init" begin
    if VERSION >= v"1.6.0-DEV.208"
        @testset for n in 0:20, f in 1:4
            @test sum(unroll(f, 1:n); init = 0) == sum(1:n)
            @test sum(unroll(f, copy([1:n 1:n]')'); init = 0) == 2 * sum(1:n)
            @test append!!(EmptyVector(), unroll(f, 1:n)) == 1:n
            @test append!!(EmptyVector(), unroll(f, copy([1:n 1:n]')')) == [1:n; 1:n]
        end
    end
end

@testset "termination" begin
    @testset for n in 1:20, f in 1:4, p in 1:10
        @test foldl(right, ReduceIf(isequal(p)), unroll(f, 1:n)) == min(n, p)
    end
end

end  # module
