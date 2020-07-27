module TestPrefetch

using LoopRecipes
using Test

@testset begin
    @test sum(sum, prefetching(1:4)) == sum(1:4)
    @test sum(sum, prefetching(map(collect, 1:4))) == sum(1:4)
    @test sum(sum, prefetching([[x] for x in 1:4])) == sum(1:4)
end

end  # module
