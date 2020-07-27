"""
    unroll(factor, xs)
    unroll(factor, indexstyle, xs)
"""
unroll
unroll(factor::Union{Val,Integer}, ::IndexLinear, xs) = Unroll(asval(factor), Val{1}(), xs)
unroll(factor::Union{Val,Integer}, ::IndexStyle, xs) =
    Unroll(asval(factor), Val{ndims(xs)}(), xs)
unroll(factor::Union{Val,Integer}, xs) = unroll(asval(factor), IndexStyle(xs), xs)

struct Unroll{F,N,T} <: Foldable
    factor::Val{F}
    ndims::Val{N}
    xs::T
end

Unroll{F,N}(xs::T) where {F,N,T} = Unroll{F,N,T}(Val{F}(), Val{N}(), xs)

@inline function Transducers.__foldl__(rf::R, acc, unrolling::Unroll{F,1}) where {R,F}
    xs = unrolling.xs
    i = firstindex(xs)
    n = lastindex(xs) - F
    while i <= n
        vals = let i = i
            ntuple(Val{F}()) do k
                @inbounds xs[i+(k-1)]
            end
        end
        acc = @return_if_reduced foldlargs(rf, acc, vals...)
        i += F
    end
    while i <= lastindex(xs)
        acc = @next(rf, acc, @inbounds xs[i])
        i += 1
    end
    return complete(rf, acc)
end

@inline function Transducers.__foldl__(rf::R, acc, unrolling::Unroll{F,N}) where {R,F,N}
    xs = unrolling.xs
    for i in axes(xs, N)
        ys = fix_right_index(xs, i)
        acc = @return_if_reduced foldl_nocomplete(rf, acc, Unroll{F,N - 1}(ys))
    end
    return complete(rf, acc)
end

struct PartiallyIndexed{I<:Tuple{Vararg{Integer}},T}
    index::I
    xs::T
end

fix_right_index(ys::PartiallyIndexed, i::Integer) =
    PartiallyIndexed((i, ys.index...), ys.xs)
fix_right_index(xs, i::Integer) = PartiallyIndexed((i,), xs)

Base.axes(ys::PartiallyIndexed, n) = axes(ys.xs, n)
Base.firstindex(ys::PartiallyIndexed) = firstindex(ys.xs, 1)
Base.lastindex(ys::PartiallyIndexed) = lastindex(ys.xs, 1)

@propagate_inbounds Base.getindex(ys::PartiallyIndexed, i::Integer) = ys.xs[i, ys.index...]
