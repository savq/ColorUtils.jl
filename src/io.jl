# String (plain) representation
Base.print(io::IO, c::URgb) = print(io, "#" * string(UInt32(c); base=16, pad=6))

# Constructor-like representation
Base.show(io::IO, c::URgb) = print(io, "rgb\"$(string(c))\"")

_colorize(::MIME"text/plain", s, c::URgb) = "\033[38;2;$(c.r);$(c.g);$(c.b)m$s\033[0m"
_colorize(::MIME"text/html", s, c::URgb) = """<span style="color:$c">$s</span>"""

_colorize(::MIME"text/plain", s, c::Color256) = "\033[38;5;$(c.v)m$s\033[0m"


function Base.show(io::IO, m::MIME"text/plain", c::URgb)
    if get(io, :color, false)
        print(io, _colorize(m, "██ ", c) * string(c))
    else
        show(io, c)
    end
end

function Base.show(io::IO, m::MIME"text/html", c::URgb)
    print(io, _colorize(m, "██ ", c) * string(c))
end

function Base.show(io::IO, m::MIME"text/plain", c::Color256)
    if get(io, :color, false)
        print(io, _colorize(m, "██ ", c) * string(c.v))
    else
        show(io, c)
    end
end

"""
    parse(::Type{Rgb{UInt8}}, str)

Parse a hex triplet as a URgb. The string must start with a '#' character,
and it must have exactly 6 hexadecimal digits.
"""
function Base.parse(::Type{URgb}, str::AbstractString)
    if length(str) != 7 || str[1] != '#'
        throw(ArgumentError("hex color string must start with '#', and have exactly 6 hex digits."))
    end
    URgb(parse(UInt32, str[2:end]; base=16))
end

"Shorthand for parse(URgb, str)"
macro rgb_str(str::AbstractString)
    parse(URgb, str)
end

# Print other color types

Base.print(io::IO, color::Rgb{Float64}) = print(io, Color{UInt8}(color))

Base.parse(::Type{Rgb{Float64}}, str) = Rgb{Float64}(parse(Rgb{UInt8}, str))

hex(color::AbstractColor) = color |> Rgb{UInt8} |> string

