"""
    simdeachindex([width,] xs)

Return a foldable that iterates over indices of `xs` using
`SIMD.VecRange` and/or integer.

`width` is an integer or a `Val` of integer that specifies the SIMD
width.

# Examples
```jldoctest simdeachindex
julia> using LoopRecipes

julia> foreach(simdeachindex(ones(10))) do i
           @show i
       end;
i = VecRange{4}(1)
i = VecRange{4}(5)
i = 9
i = 10
```
"""
simdeachindex(xs) = simdeachindex(Val{4}(), xs)
simdeachindex(width::Integer, xs) = simdeachindex(Val{width}(), xs)
simdeachindex(width::Val, xs) = SIMDEachIndex(width, firstindex(xs), lastindex(xs))
# TODO: support CartesianIndices

struct SIMDEachIndex{W} <: Foldable
    width::Val{W}
    firstindex::Int
    lastindex::Int
end

@inline function Transducers.__foldl__(rf, init, foldable::SIMDEachIndex{W}) where {W}
    i = foldable.firstindex
    n = foldable.lastindex - W
    lane = VecRange{W}(0)
    if i <= n
        vacc = @next(rf, init, lane + i)
        i += W
    end
    while i <= n
        vacc = @next(rf, vacc, lane + i)
        i += W
    end
    if i <= foldable.lastindex
        acc = @next(rf, vacc, i)
        i += 1
    end
    while i <= foldable.lastindex
        acc = @next(rf, acc, i)
        i += 1
    end
    return complete(rf, acc)
end

"""
    simdpairs([width,] xs)

Return a foldable that iterates over index-value pairs of `xs` using
`SIMD.VecRange` and `SIMD.Vec` for the main part.

`width` is an integer or a `Val` of integer that specifies the SIMD
width.

# Examples
```jldoctest simdpairs
julia> using LoopRecipes

julia> foreach(simdpairs(collect(100:100:1000))) do (i, v)
           @show i v
       end;
i = VecRange{4}(1)
v = <4 x Int64>[100, 200, 300, 400]
i = VecRange{4}(5)
v = <4 x Int64>[500, 600, 700, 800]
i = 9
v = 900
i = 10
v = 1000
```

Since the same loop body (aka `op` or `rf`) is used for all stages of
the iteration, the accumulator `acc` should be properly reduced
depending on the type of `v`:

```jldoctest simdpairs
julia> using SIMD  # for Vec

julia> foldl(simdpairs(collect(1:10)); init = 0) do acc, (_, v)
           x = 2 * v
           (v isa Vec ? acc : sum(acc)) + x
       end
110
```
"""
simdpairs(xs) = simdpairs(Val{4}(), xs)
simdpairs(width::Integer, xs) = simdpairs(Val{width}(), xs)
function simdpairs(width::Val, xs)
    @inline getpair(i) = i => @inbounds xs[i]
    return simdeachindex(width, xs) |> Map(getpair)
end

"""
    simdstored([width,] xs)

Return a foldable that iterates over stored index-value pairs of `xs`
using `SIMD.Vec` for the main part.

`width` is an integer or a `Val` of integer that specifies the SIMD
width.

# Examples
For dense arrays, `simdstored` is identical to [`simdpairs`](@ref):

```jldoctest simdstored
julia> using LoopRecipes

julia> foreach(simdstored(collect(1:10))) do (i, v)
           @show i v
       end;
i = VecRange{4}(1)
v = <4 x Int64>[1, 2, 3, 4]
i = VecRange{4}(5)
v = <4 x Int64>[5, 6, 7, 8]
i = 9
v = 9
i = 10
v = 10
```

For parse arrays, `simdstored` iterates over only stored index-value
pairs:

```jldoctest simdstored
julia> using SparseArrays

julia> xs = SparseVector(10, [1, 3, 4, 7, 8], [1, 2, 3, 4, 5]);

julia> foreach(simdstored(xs)) do (i, v)
           @show i v
       end;
i = <4 x Int64>[1, 3, 4, 7]
v = <4 x Int64>[1, 2, 3, 4]
i = 8
v = 5
```

Like [`simdpairs`](@ref), the accumulator `acc` should be properly
reduced depending on the type of `v`:

```jldoctest simdstored
julia> using SIMD  # for Vec

julia> foldl(simdstored(xs); init = 0) do acc, (_, v)
           x = 2 * v
           (v isa Vec ? acc : sum(acc)) + x
       end
30
```
"""
simdstored(xs) = simdstored(Val{4}(), xs)
simdstored(width::Integer, xs) = simdstored(Val{width}(), xs)
simdstored(width::Val, xs) = simdpairs(width, xs)
function simdstored(width::Val, xs::AbstractSparseArray)
    vals = nonzeros(xs)
    @inline getpair((k, i),) = i => @inbounds vals[k]
    return simdpairs(width, nonzeroinds(xs)) |> Map(getpair)
end
# TODO: support matrices
