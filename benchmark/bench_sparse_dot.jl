module BenchSparseDot

using BenchmarkTools
using LinearAlgebra: dot
using LoopRecipes
using Random: Random
using SIMD: Vec
using SparseArrays: SparseVector, sprandn

Random.seed!(1234)

const SUITE = BenchmarkGroup()

function simddot(xs::SparseVector, ys::Vector)
    foldl(simdstored(xs); init = zero(eltype(xs)) * zero(eltype(ys))) do acc, (i, x)
        Base.@_inline_meta
        (x isa Vec ? acc : sum(acc)) + @inbounds x * ys[i]
    end
end

for p in 8:10
    n = 2^p
    xs = sprandn(n, 0.1)
    ys = randn(n)
    @assert dot(xs, ys) ≈ simddot(xs, ys)

    s1 = SUITE[:n=>n] = BenchmarkGroup()
    s1[:impl=>:base] = @benchmarkable dot($xs, $ys)
    s1[:impl=>:folds] = @benchmarkable simddot($xs, $ys)
end

end  # module
BenchSparseDot.SUITE
