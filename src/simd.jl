"""
    simdeachindex([width,] xs)

Return a foldable that iterates over indices of `xs` using
`SIMD.VecRange` and/or integer.

`width` is an integer or a `Val` of integer that specifies the SIMD
width.

# Examples
```jldoctest simdeachindex; filter = r"(SIMD\\.)?VecRange"
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
        while i <= n
            vacc = @next(rf, vacc, lane + i)
            i += W
        end
    end
    if i <= foldable.lastindex
        acc = @next(rf, vacc, i)
        i += 1
        while i <= foldable.lastindex
            acc = @next(rf, acc, i)
            i += 1
        end
    end
    return complete(rf, acc)
end

"""
    simdpairs([width,] xs)

Return a foldable that iterates over index-value pairs of `xs` using
`SIMD.VecRange` and `SIMD.Vec` for the main part.

`width` is an integer or a `Val` of integer that specifies the SIMD
width.

See also [`simdeachindex`](@ref).

# Examples
```jldoctest simdpairs; filter = r"(SIMD\\.)?VecRange"
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

Thanks to `setindex!` overload on `VecRange`, it is straightforward to
use it for implementing a simple mapping.

```jldoctest simdpairs
julia> function double!(ys, xs)
           @assert axes(ys) == axes(xs)
           foreach(simdpairs(xs)) do (i, x)
               @inbounds ys[i] = 2x
           end
           return ys
       end;

julia> double!(zeros(5), ones(5))
5-element Array{Float64,1}:
 2.0
 2.0
 2.0
 2.0
 2.0
```

When using `simdpairs` for reduction, the accumulator `acc` should be
properly reduced depending on the type of `v`.  This is because the
same loop body (aka `op` or `rf`) is used for all stages of the
iteration.

```jldoctest simdpairs
julia> using SIMD  # for Vec

julia> foldl(simdpairs(collect(1:10)); init = 0) do acc, (_, v)
           x = 2 * v
           (v isa Vec ? acc : sum(acc)) + x
       end
110
```

Here is another example for demonstrating how `v isa Vec` works:

```jldoctest simdpairs
julia> foldl(simdpairs(collect(10:24)); init = 0) do acc, (i, v)
           @show first(i), acc, v
           (v isa Vec ? acc : sum(acc)) + v
       end
(first(i), acc, v) = (1, 0, <4 x Int64>[10, 11, 12, 13])
(first(i), acc, v) = (5, <4 x Int64>[10, 11, 12, 13], <4 x Int64>[14, 15, 16, 17])
(first(i), acc, v) = (9, <4 x Int64>[24, 26, 28, 30], <4 x Int64>[18, 19, 20, 21])
(first(i), acc, v) = (13, <4 x Int64>[42, 45, 48, 51], 22)
(first(i), acc, v) = (14, 208, 23)
(first(i), acc, v) = (15, 231, 24)
255
```

Observe that:

(1) When at the first iteration (`first(i) == 1`), `acc` is `0` (as
specified by `init = 0`).  This is broadcast to a `Vec` because `v` is
a `Vec`.  See that `acc` in the second iteration (`first(i) == 5`) is
a `Vec` (`<4 x Int64>[10, 11, 12, 13]`).

(2) At the second and third iterations, both `acc` and `v` are `Vec`,
yielding an `acc::Vec` for the next iteration.

(3) At the iteration `first(i) == 13`, `v` is not `Vec` (i.e., we are
in the reminder loop).  Thus, `acc` (`<4 x Int64>[42, 45, 48, 51]`) is
reduced a scalar before adding `v` (`22`).  See that `acc` in the next
iteration is a scalar (`208`).

(4) Final two iterations deals with scalar `acc` and `v`.  Note that
we do not need a special code since `sum(::Number)` is an identity
function.

!!! note

    Since [`simdeachindex`](@ref) and thus `simdpairs` uses
    `Transducers.__foldl__` instead of `Base.iterate` to implement the
    iteration, these four stages are all properly type-stabilized.

These may look complicated but the rule is simple: the returned value
of the reducing function (i.e., accumulation result) should have the
same "shape" as the input value `v`.
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

```jldoctest simdstored; filter = r"(SIMD\\.)?VecRange"
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

Sparse-dense dot product:

```jldoctest simdstored
julia> function simddot(xs::SparseVector, ys)
           init = zero(eltype(xs)) * zero(eltype(ys))
           foldl(simdstored(xs); init = init) do acc, (i, x)
               Base.@_inline_meta
               (x isa Vec ? acc : sum(acc)) + @inbounds x * ys[i]
           end
       end;

julia> simddot(xs, [1:10;])
87
```

Identical function written using FLoops.jl:

```jldoctest simdstored
julia> using FLoops

julia> function simddot′(xs::SparseVector, ys)
           @floop begin
               acc = zero(eltype(xs)) * zero(eltype(ys))
               for (i, x) in simdstored(xs)
                   acc = (x isa Vec ? acc : sum(acc)) + @inbounds x * ys[i]
               end
               acc
           end
       end;

julia> simddot′(xs, [1:10;])
87
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
