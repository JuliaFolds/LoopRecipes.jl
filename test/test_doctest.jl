module TestDoctest

import LoopRecipes
using Documenter: doctest
using Test

@testset "doctest" begin
    doctest(LoopRecipes)
end

end  # module
