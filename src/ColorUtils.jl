module ColorUtils

export ColorRGB
export Color256
export generate_xterm_colors

abstract type AbstractColor end

struct ColorRGB <: AbstractColor
    r::UInt8
    g::UInt8
    b::UInt8
end

ColorRGB(r::N, g::N, b::N) where {N<:Integer} = ColorRGB(UInt8.((r, g, b))...) # throws InexactError

ColorRGB(c::UInt32) = ColorRGB(c >> 16, (c & 0xff00) >> 8, c & 0xff) # 1 UInt32 into 3 UInt8

ColorRGB(c::N) where {N<:Integer} = ColorRGB(UInt32(c)) # throws InexactError

struct Color256 <: AbstractColor
    v::UInt8
end

# generic struct iteration (for splats)
function Base.iterate(c::ColorRGB, state = 0)::Tuple{UInt8, Int}
    if state < nfields(c); (Base.getfield(c, state+1), state+1) else nothing end
end

ansi_style(s::AbstractString, c::ColorRGB) = "\033[38;2;$(c.r);$(c.g);$(c.b)m$s\033[0m"
ansi_style(s::AbstractString, c::Color256) = "\033[38;5;$(c.v)m$s\033[0m"
Base.print(io::IO, c::AbstractColor) = print(io, ansi_style("████", c))

# An eclidean metric probably isn't the best way to compare colors, but whatever
dist(p::ColorRGB, q::ColorRGB) = √sum((Float64.((p...,)) .- Float64.((q...,))) .^ 2.0)

function quantize(color::ColorRGB, palette::Vector{ColorRGB})
    m = Inf
    c = color
    for p in palette
        newmin = min(m, dist(color, p))
        if newmin ≠ m
            m = newmin
            c = p
        end
    end
    return c
end

function quantize(colors::Vector{ColorRGB}, palette::Vector{ColorRGB})
    l = length(colors)
    new_colors = Vector(undef, l)
    for i in 1:l
        new_colors[i] = quantize(colors[i], palette)
    end
    return new_colors
end

"Compute the true color (ColorRGB) equivalents of xterm's 256 color palette (Color256)."
function generate_xterm_colors()::Vector{ColorRGB}
    i = 1 # Yes. colors[1] = 0x000000  
    colors = Vector(undef, 257)

    # Generate first 16 colors
    for factor in 1:-1:0
        o = [false, true]
        for b in o, g in o, r in o
            colors[i] = ColorRGB(
                r ? (255 >> factor) : 0,
                g ? (255 >> factor) : 0,
                b ? (255 >> factor) : 0
            )
            i += 1
        end
    end

    colors[8] = ColorRGB(0x808080) # this is dumb
    colors[9] = ColorRGB(0xc0c0c0)

    # Generate the ``color cube''
    for r in 0:5, g in 0:5, b in 0:5
        colors[i] = ColorRGB(
            r == 0 ? 0 : r * 40 + 55,
            g == 0 ? 0 : g * 40 + 55,
            b == 0 ? 0 : b * 40 + 55
        )
        i += 1
    end

    # Generate gray-scale colors
    for gray in 0:24
        val = gray * 10 + 8
        colors[i] = ColorRGB(val, val, val)
        i += 1
    end

    return colors
end

# Check if a terminal emulator has true color support
# and if it uses the same algorithm to produce 256 colors as xterm
function check_term_colors()
    xterm_colors = generate_xterm_colors()
    for i in 0:255
        println(i, Color256(i), xterm_colors[i+1])
    end
end

end # module
