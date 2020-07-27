module LoopRecipes

export prefetching, unroll

using Base: @propagate_inbounds
using Transducers:
    @next,
    @return_if_reduced,
    Foldable,
    R_,
    Transducer,
    Transducers,
    Unseen,
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

end
