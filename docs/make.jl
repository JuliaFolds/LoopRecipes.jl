using Documenter
using LoopRecipes
using SIMD  # for doctests (TODO: use filter)

makedocs(;
    sitename = "LoopRecipes",
    format = Documenter.HTML(),
    modules = [LoopRecipes]
)

deploydocs(;
    repo = "github.com/JuliaFolds/LoopRecipes.jl",
    push_preview = true,
)
