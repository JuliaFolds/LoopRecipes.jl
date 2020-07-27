module LoopRecipes

export prefetching, simdeachindex, simdpairs, simdstored, unroll

using Base: @propagate_inbounds
using SIMD: VecRange
using SparseArrays: AbstractSparseArray, nonzeroinds, nonzeros
using Transducers:
    @next,
    @return_if_reduced,
    Foldable,
    Map,
    R_,
    Transducer,
    Transducers,
    Unseen,
    __foldl__,
    complete,
    foldl_nocomplete,
    foldlargs,
    inner,
    next,
    start,
    unwrap,
    wrap,
    wrapping

include("utils.jl")
include("unroll.jl")
include("prefetch.jl")
include("simd.jl")

end
