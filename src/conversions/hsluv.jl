"""
An implementation of [HSLuv](https://github.com/hsluv/hsluv) (rev4).
"""
module HsluvColors

using ..ColorUtils: AbstractColor
using ..RGBColors: RGB, XYZ, RGB_from_XYZ

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

struct Line
    slope::Float64
    intercept::Float64
end

const REF_U = 0.19783000664283681
const REF_V = 0.468319994938791

# CIE LUV constants
const KAPPA = (29 / 3)^3    # 903.2962962962963
const EPSILON = (6 / 29)^3  # 0.0088564516790356308


function distance_from_origin(l::Line)
    return abs(l.intercept) / sqrt((l.slope ^ 2) + 1)
end

function length_of_ray_until_intersect(θ, l::Line)
    return l.intercept / (sin(θ) - l.slope * cos(θ))
end

"""
For a given lightness, return a list of 6 lines in slope-intercept form that
represent the bounds in CIELUV, stepping over which will push a value out of
the RGB gamut.
"""
function get_bounds(l::Float64)::Vector{Line}
    result = Vector{Line}(undef, 6)
    sub1 = (l + 16)^3 / 1560896
    sub2 = sub1 > EPSILON ? sub1 : l / KAPPA

    i = 0
    for c in 1:3, t in 0:1
        m = RGB_from_XYZ[c, :]
        top1 = (284517 * m[1] - 94839 * m[3]) * sub2
        top2 = (838422 * m[3] + 769860 * m[2] + 731718 * m[1]) * l * sub2 - 769860 * t * l
        bottom = (632260 * m[3] - 126452 * m[2]) * sub2 + 126452 * t

        result[i+=1] = Line(top1 / bottom, top2 / bottom)
    end

    return result
end


"""
For given lightness, returns the maximum chroma. Keeping the chroma value below
this number will ensure that for any hue, the color is within the RGB gamut.
"""
function max_chroma(l)
    minimum(distance_from_origin, get_bounds(l))
end

function max_chroma(l, h)
    hrad = deg2rad(h)
    # FIXME: Why does `length...` return negative values???
    minimum(get_bounds(l)) do bound
        len = length_of_ray_until_intersect(hrad, bound)
        len >= 0 ? len : Inf
    end
end

function Luv((; x, y, z)::XYZ)
    l = y <= EPSILON ? (y * KAPPA) : 116 * y^(1.0 / 3.0) - 16

    if l == 0
        Luv(0, 0, 0)
    else
        divider = x + 15 * y + 3 * z
        _u = 4 * x / divider
        _v = 9 * y / divider

        u = 13 * l * (_u - REF_U)
        v = 13 * l * (_v - REF_V)
        Luv(l, u, v)
    end
end

function XYZ((; l, u, v)::Luv)
    if l == 0
        XYZ(0, 0, 0)
    else
        y = l <= 8 ? (l / KAPPA) : ((l + 16) / 116)^3

        _u = u / (13 * l) + REF_U
        _v = v / (13 * l) + REF_V

        x = (y * 9 * _u) / (4 * _v)
        z = y * (12 - 3 * _u - 20 * _v) / (4 * _v)
        XYZ(x, y, z)
    end
end

function Lch((; l, u, v)::Luv)
    c = sqrt(u * u + v * v)

    # greys: disambiguate hue
    h = if c < 0.00000001
        0
    else
        _h = rad2deg(atan(v, u))
        _h < 0 ? _h + 360 : _h
    end

    Lch(l, c, h)
end

function Luv((; l, c, h)::Lch)
    hrad = deg2rad(h)
    Luv(
        l,
        cos(hrad) * c,
        sin(hrad) * c,
    )
end

function Lch((; h, s, l)::Hsluv)
    # White and black: disambiguate chroma
    if l > 99.9999999
        Lch(100, 0, h)
    elseif l < 0.00000001
        Lch(0, 0, h)
    else
        c = max_chroma(l, h) / 100.0 * s
        Lch(l, c, h)
    end
end

function Hsluv((; l, c, h)::Lch)
    # White and black: disambiguate chroma
    if l > 99.9999999
        Hsluv(h, 0, 100)
    elseif l < 0.00000001
        Hsluv(h, 0, 0)
    else
        s = c / max_chroma(l, h) * 100.0
        Hsluv(h, s, l)
    end
end

function Lch((; h, s, l)::Hpluv)
    if l > 99.9999999
        Lch(100, 0, h)
    elseif l < 0.00000001
        Lch(0, 0, h)
    else
        c = max_chroma(l) / 100.0 * s
        Lch(l, c, h)
    end
end

function Hpluv((; l, c, h)::Lch)
    if l > 99.9999999
        Hpluv(h, 0, 100)
    elseif l < 0.00000001
        Hpluv(h, 0, 0)
    else
        s = c / max_chroma(l) * 100.0
        Hpluv(h, s, l)
    end
end

RGB(color::Lch) = color |> Luv |> XYZ |> RGB
Lch(color::RGB) = color |> XYZ |> Luv |> Lch

RGB(color::Hsluv) = color |> Lch |> RGB
Hsluv(color::RGB) = color |> Lch |> Hsluv

RGB(color::Hpluv) = color |> Lch |> RGB
Hpluv(color::RGB) = color |> Lch |> Hpluv

Hsluv(color::AbstractColor) = color |> RGB |> Hsluv
Hpluv(color::AbstractColor) = color |> RGB |> Hpluv

end # module
