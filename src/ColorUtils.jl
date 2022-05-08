module ColorUtils

export Color256
export ColorRGB
export quantize
export generate_xterm_colors
export check_term_colors

import Base.parse
import Base.iterate

abstract type AbstractColor end

struct Color256 <: AbstractColor
    v::UInt8
end

struct ColorRGB <: AbstractColor
    r::UInt8
    g::UInt8
    b::UInt8
end

ColorRGB(c::UInt32) = ColorRGB(c >> 16, (c & 0xff00) >> 8, c & 0xff) # 1 UInt32 into 3 UInt8

# ColorRGB(r::N, g::N, b::N) where {N<:Integer} = ColorRGB(UInt8.((r, g, b))...) # throws InexactError
# ColorRGB(c::N) where {N<:Integer} = ColorRGB(UInt32(c)) # throws InexactError

# generic struct iteration (for splats)
Base.iterate(c::ColorRGB, state = 0) = state < nfields(c) ? (Base.getfield(c, state+1), state+1) : nothing


### IO

"""
    parse(::Type{ColorRGB}, str)

Parse a hex triplet as a ColorRGB. The string must start with a '#' character,
and it must have exactly 6 digits.
"""
function Base.parse(::Type{ColorRGB}, str)
    l = length(str)
    str[1] != Char(0x23) && throw(ArgumentError("hex color string must start with a '#'"))
    l != 7 && throw(ArgumentError("hex color string is not the right size. Got $l expected 7"))
    ColorRGB(parse(UInt32, str[2:end]; base=16))
end

macro rgb_str(s)
    Base.parse(ColorRGB, s)
end

_ansi_style(s::AbstractString, c::ColorRGB) = "\033[38;2;$(c.r);$(c.g);$(c.b)m$s\033[0m"
_ansi_style(s::AbstractString, c::Color256) = "\033[38;5;$(c.v)m$s\033[0m"

# TODO:  show/print/display? MIME types?
Base.show(io::IO, ::MIME"text/plain", c::AbstractColor) = print(io, _ansi_style("███", c))


### Color quantization

"""
    generate_xterm_colors()::Vector{ColorRGB}

Compute the array of true color (ColorRGB) equivalents for xterm's 256 color palette (Color256).
"""
function generate_xterm_colors()::Vector{ColorRGB}
    colors = Vector(undef, 256)
    _fill_16_colors!(colors)
    _fill_color_cube!(colors)
    _fill_gray_ramp!(colors)
    return colors
end

function _fill_16_colors!(colors)
    i = 1
    for factor in [true, false]
        💡 = [false, true]
        for b in 💡, g in 💡, r in 💡
            colors[i] = ColorRGB(
                r ? (255 >>> factor) + factor : 0,
                g ? (255 >>> factor) + factor : 0,
                b ? (255 >>> factor) + factor : 0
            )
            i += 1
        end
    end

    colors[9] = colors[8]
    colors[8] = ColorRGB(([colors[8]...] .+ 64)...)
    return
end

function _fill_color_cube!(colors)
    i = 17
    for r in 0:5, g in 0:5, b in 0:5
        colors[i] = ColorRGB(
            r == 0 ? 0 : r * 40 + 55,
            g == 0 ? 0 : g * 40 + 55,
            b == 0 ? 0 : b * 40 + 55
        )
        i += 1
    end
end

function _fill_gray_ramp!(colors)
    # Generate gray-scale colors
    i = 17 + 216
    for gray in 0:23
        val = gray * 10 + 8
        colors[i] = ColorRGB(val, val, val)
        i += 1
    end
end

# An eclidean metric probably isn't the best way to compare colors, but whatever
_dist(p::ColorRGB, q::ColorRGB) = √sum((Float64.((p...,)) .- Float64.((q...,))) .^ 2.0)

function quantize(color::ColorRGB, palette::Vector{ColorRGB})
    m = Inf
    c = color
    idx = 1
    for (i, p) in enumerate(palette)
        newmin = min(m, _dist(color, p))
        if newmin != m
            m = newmin
            c = p
            idx = i
        end
    end
    return c, idx
end

function quantize(colors::Vector{ColorRGB}, palette::Vector{ColorRGB})
    # map(quantize, colors, palette)
    l = length(colors)
    new_colors = Vector(undef, l)
    for i in 1:l
        new_colors[i] = quantize(colors[i], palette)
    end
    return new_colors
end

const XTERM_COLORS = generate_xterm_colors()

quantize(color::ColorRGB) = quantize(color, XTERM_COLORS)
quantize(colors::Vector{ColorRGB}) = quantize(colors, XTERM_COLORS)

# Check if a terminal emulator has true color support
# and if it uses the same algorithm to produce 256 colors as xterm
function check_term_colors()
    for i in 0:255
        println(i, Color256(i), XTERM_COLORS[i+1])
    end
end

end # module
