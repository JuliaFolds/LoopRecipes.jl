module BenchPrefetch

using BenchmarkTools
using LoopRecipes
using Random: Random, shuffle!

Random.seed!(1234)

const SUITE = BenchmarkGroup()

for p in 14:16
    n = 2^p
    xs = [randn(32) for _ in 1:n]
    shuffle!(xs)
    @assert sum(sum, xs) ≈ sum(sum, prefetching(xs))

    s1 = SUITE[:n=>n] = BenchmarkGroup()
    s1[:impl=>:base] = @benchmarkable sum(sum, $xs)
    s1[:impl=>:folds] = @benchmarkable sum(sum, prefetching($xs))
end

end  # module
BenchPrefetch.SUITE
