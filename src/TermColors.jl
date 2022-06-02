const ColorRGB = Rgb{UInt8} # FIXME: Remove

# String (plain) representation
print(io::IO, c::ColorRGB) = print(io, "#" * string(UInt32(c); base=16, pad=6))

# Constructor-like representation
show(io::IO, c::ColorRGB) = print(io, "rgb\"$(string(c))\"")

_colorize_ansi(s, c::Color256) = "\033[38;5;$(c.v)m$s\033[0m"
_colorize_ansi(s, c::ColorRGB) = "\033[38;2;$(c.r);$(c.g);$(c.b)m$s\033[0m"

function show(io::IO, ::MIME"text/plain", c::Color256)
    if get(io, :color, false)
        print(io, _colorize_ansi("██ ", c) * string(c.v))
    else
        show(io, c)
    end
end

function show(io::IO, ::MIME"text/plain", c::ColorRGB)
    if get(io, :color, false)
        print(io, _colorize_ansi("██ ", c) * string(c))
    else
        show(io, c)
    end
end

# TODO: MIME HTML

"""
    parse(::Type{ColorRGB}, str)

Parse a hex triplet as a ColorRGB. The string must start with a '#' character,
and it must have exactly 6 hexadecimal digits.
"""
function parse(::Type{ColorRGB}, str::AbstractString)
    if length(str) != 7 || str[1] != '#'
        throw(ArgumentError("hex color string must start with '#', and have exactly 6 hex digits."))
    end
    ColorRGB(parse(UInt32, str[2:end]; base=16))
end

"Shorthand for parse(ColorRGB, str)"
macro rgb_str(str::AbstractString)
    parse(ColorRGB, str)
end


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
    i = 0
    for factor in [1, 0]
        💡 = [false, true]
        for b in 💡, g in 💡, r in 💡
            colors[i+=1] = ColorRGB(
                r ? (255 >>> factor) + factor : 0,
                g ? (255 >>> factor) + factor : 0,
                b ? (255 >>> factor) + factor : 0
            )
        end
    end

    colors[9] = colors[8]
    colors[8] = ColorRGB([colors[8]...] .+ 64 ...)
    return
end

function _fill_color_cube!(colors)
    i = 16
    💡 = 1:5
    for r in 💡, g in 💡, b in 💡
        colors[i+=1] = ColorRGB(
            r == 0 ? 0 : r * 40 + 55,
            g == 0 ? 0 : g * 40 + 55,
            b == 0 ? 0 : b * 40 + 55
        )
    end
end

function _fill_gray_ramp!(colors)
    colors[233:256] = map(0:23) do gray
        val = gray * 10 + 8
        ColorRGB(val, val, val)
    end
    return
end

# TODO: Use Hsluv.Rgb here instead
_dist(p::ColorRGB, q::ColorRGB) = √sum((Float64[p...] .- Float64[q...]) .^ 2.0)

const XTERM_COLORS = generate_xterm_colors()

function quantize(color::ColorRGB, palette::Vector{ColorRGB}=XTERM_COLORS)
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
