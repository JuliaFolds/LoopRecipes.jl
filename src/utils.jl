asval(x::Val) = x
asval(x) = Val(x)

valof(::Val{x}) where {x} = x
valof(x) = x
