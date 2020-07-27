module LoopRecipes

export unroll

using Base: @propagate_inbounds
using Transducers:
    @next, @return_if_reduced, Foldable, Transducers, complete, foldl_nocomplete, foldlargs

include("utils.jl")
include("unroll.jl")

end
