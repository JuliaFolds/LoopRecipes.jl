# LoopRecipes: composable loops

[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://juliafolds.github.io/LoopRecipes.jl/dev)
[![GitHub Actions](https://github.com/JuliaFolds/LoopRecipes.jl/workflows/CI/badge.svg)](https://github.com/JuliaFolds/LoopRecipes.jl/actions?query=workflow%3ACI)

LoopRecipes.jl provides several constructs for high-performance loops
based on the extended `foldl` protocol of
[Transducers.jl](https://github.com/JuliaFolds/Transducers.jl).

## API summary

* `unroll([factor,] xs)`: Unroll an array `xs` by a given `factor`.
* `prefetching(xs)`: Prefetch each element in `xs`.  It works when
  `xs` is a nested data structure (e.g., vector of vectors, vector of
  strings).
* `simdeachindex([width,] xs)`: Iterate over indices of `xs` using
  `SIMD.VecRange`.  It also takes care of the remainder loop.
* `simdpairs([width,] xs)`: Iterate over index-value pairs of `xs`
  using `SIMD.VecRange` and `SIMD.Vec`.  It also takes care of the
  remainder loop.
* `simdstored([width,] xs)`: For a sparse array `xs`, iterate over
  stored index-value pairs of `xs` using `SIMD.Vec`.  It also takes
  care of the remainder loop.
