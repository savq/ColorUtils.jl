abstract type AbstractColor end

struct Rgb{N <: Union{Float64, UInt8}} <: AbstractColor
    r::N
    g::N
    b::N
end

const URgb = Rgb{UInt8}

struct Hsluv <: AbstractColor
    h::Float64
    s::Float64
    l::Float64
end

struct Hpluv <: AbstractColor
    h::Float64
    s::Float64
    l::Float64
end

struct Lch <: AbstractColor
    l::Float64
    c::Float64
    h::Float64
end

struct Luv <: AbstractColor
    l::Float64
    u::Float64
    v::Float64
end

struct Xyz <: AbstractColor
    x::Float64
    y::Float64
    z::Float64
end

"8-bit color"
struct Color256 #  TODO: Should this be an AbstractColor subtype?
    v::UInt8
end

# For splats
function Base.iterate(c::AbstractColor, state = 0)
    state < nfields(c) ? (Base.getfield(c, state + 1), state + 1) : nothing
end

