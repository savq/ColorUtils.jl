module ColorIO

using ..ColorUtils: AbstractColor
using ..RGBColors: RGB24
using ..TermColors: Color8

# Plain representation
function Base.print(io::IO, (; r, g, b)::RGB24)
    rgb = UInt32.((r, g, b))
    n = (rgb[1] << 16) + (rgb[2] << 8) + rgb[3]
    print(io, "#" * string(n; base=16, pad=6))
end

# Constructor-like representation
Base.show(io::IO, rgb::RGB24) = print(io, "rgb\"$(string(rgb))\"")

# TODO: Replace with StyledStrings
_colorize(::MIME"text/plain", s, rgb::RGB24) = "\033[38;2;$(rgb.r);$(rgb.g);$(rgb.b)m$s\033[0m"
_colorize(::MIME"text/html", s, rgb::RGB24) = """<span style="color:$rgb">$s</span>"""

_colorize(::MIME"text/plain", s, c::Color8) = "\033[38;5;$(c.n)m$s\033[0m"

function Base.show(io::IO, m::MIME"text/plain", rgb::RGB24)
    if get(io, :color, false)
        print(io, _colorize(m, "██ ", rgb) * string(rgb))
    else
        show(io, rgb)
    end
end

function Base.show(io::IO, m::MIME"text/html", rgb::RGB24)
    print(io, _colorize(m, "██ ", rgb) * string(rgb))
end

function Base.show(io::IO, m::MIME"text/plain", c::Color8)
    if get(io, :color, false)
        print(io, _colorize(m, "██ ", c) * string(c.n))
    else
        show(io, c)
    end
end

# TODO: hex triplets with only 3 hex digits.
"""
    parse(::Type{RGB24}, str)

Parse a hex triplet as a RGB24. The string must start with a '#' character,
and it must have exactly 6 hexadecimal digits.
"""
function Base.parse(::Type{RGB24}, str::AbstractString)
    if length(str) != 7 || str[1] != '#'
        throw(ArgumentError("hex color string must start with '#', and have exactly 6 hex digits."))
    end
    RGB24(parse(UInt32, str[2:end]; base=16))
end

"Shorthand for parse(RGB24, str)"
macro rgb_str(str::AbstractString)
    parse(RGB24, str)
end

# Print other color types

Base.print(io::IO, color::AbstractColor) = print(io, RGB24(color))
Base.show(io::IO, color::AbstractColor) = show(io, RGB24(color))

hex(color::AbstractColor) = string(RGB24(color))

end # module
