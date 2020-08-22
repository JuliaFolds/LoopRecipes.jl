"""
    prefetching(xs)

Prefetch each boxed element in `xs`.  It can be used when `xs` is a
nested data structure (e.g., vector of vectors, vector of strings).
Do nothing when the element of `xs` is not boxed.

# Examples
```jldoctest
julia> using LoopRecipes

julia> sum(sum, prefetching([[1], [2, 3], [4, 5, 6]]))
21

julia> using FLoops

julia> @floop begin
           acc = 0
           for x in prefetching([[1], [2, 3], [4, 5, 6]])
               acc += sum(x)
           end
           acc
       end
21
```
"""
prefetching(xs) = xs |> Prefetching()

struct Prefetching <: Transducer end

@inline Transducers.start(rf::R_{Prefetching}, init) =
    wrap(rf, Unseen(), start(inner(rf), init))

@inline Transducers.next(rf::R_{Prefetching}, acc, x) =
    wrapping(rf, acc) do prev, iacc
        Base.@_inline_meta
        tryprefetch(x)
        if prev isa Unseen
            return x, iacc
        else
            return x, next(inner(rf), iacc, prev)
        end
    end

@inline function Transducers.complete(rf::R_{Prefetching}, acc)
    prev, iacc = unwrap(rf, acc)
    if !(prev isa Unseen)
        iacc = @next(inner(rf), iacc, prev)
    end
    return complete(inner(rf), iacc)
end

function Transducers.combine(rf::R_{Prefetching}, a, b)
    pa, ia = unwrap(rf, a)
    pb, ib = unwrap(rf, b)
    if !(pa isa Unseen)
        ia = @next(inner(rf), ia, pa)
    end
    ic = @return_if_reduced combine(inner(rf), ia, ib)
    if !(pb isa Unseen)
        ic = @next(inner(rf), ic, pb)
    end
    return wrap(rf, Unseen(), ic)
end

"""
    unsafe_prefetch(
        address::Union{Ptr,Integer},
        ::Val{rw} = Val(:read),
        ::Val{locality} = Val(0),
        ::Val{cache_type} = Val(:data),
    )

# Arguments
- `rw`: `:read` (0) or `:write` (1)
- `locality`: no locality/NTA (0) -- extremely local/T0 (3)
- `cache_type`: `:data` (1) or `:instruction` (0)
"""
unsafe_prefetch

@generated function unsafe_prefetch(
    address::Union{Ptr,Integer},
    ::Val{rw} = Val(:read),
    ::Val{locality} = Val(0),
    ::Val{cache_type} = Val(:data),
) where {locality,rw,cache_type}

    rw = get(Dict(:read => 0, :write => 1), rw, rw)
    cache_type = get(Dict(:data => 1, :instruction => 0), cache_type, cache_type)

    @assert rw in (0, 1)
    @assert locality in 0:3
    @assert cache_type in (0, 1)

    declaration = "declare void @llvm.prefetch(i8*, i32, i32, i32)"

    typ = (Int === Int64 ? "i64" : "i32")
    instructions = """
    %addr = inttoptr $typ %0 to i8*
    call void @llvm.prefetch(i8* %addr, i32 $rw, i32 $locality, i32 $cache_type)
    ret void
    """
    if VERSION < v"1.6.0-DEV.674"
        IR = (declaration, instructions)
    else
        IR = (
            """
            $declaration

            define void @entry($typ) #0 {
            top:
                $instructions
            }

            attributes #0 = { alwaysinline }
            """,
            "entry",
        )
    end

    quote
        $(Expr(:meta, :inline))
        Base.llvmcall($IR, Cvoid, Tuple{Ptr{Cvoid}}, address)
    end
end

# Since `tryprefetch` does not change the result of execution at all,
# using `return_type` like this should be OK?
@inline function tryprefetch(x::T) where {T}
    R = Core.Compiler.return_type(pointer, Tuple{T})
    if R !== Union{} && R <: Ptr
        unsafe_prefetch(pointer(x))
    end
end
