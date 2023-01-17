const M = [
    3.2409699419045214    -1.5373831775700935  -0.49861076029300328
    -0.96924363628087983   1.8759675015077207   0.041555057407175613
    0.055630079696993609  -0.20397695888897657  1.0569715142428786
]

const MINV = [
    0.41239079926595948   0.35758433938387796  0.18048078840183429
    0.21263900587151036   0.71516867876775593  0.072192315360733715
    0.019330818715591851  0.11919477979462599  0.95053215224966058
]


# const REF_Y = 1.0 # TODO: Why is refY defined? It's only used as a multiplicative constant...

const REF_U = 0.19783000664283681
const REF_V = 0.468319994938791

# CIE LUV constants
const KAPPA = (29 / 3)^3    # 903.2962962962963
const EPSILON = (6 / 29)^3  # 0.0088564516790356308

"""
For a given lightness, return a list of 6 lines in slope-intercept form that
represent the bounds in CIELUV, stepping over which will push a value out of
the Rgb gamut.
"""
function get_bounds(l::Float64)::Vector{Line}
    result = Vector{Line{Float64}}(undef, 6)
    sub1 = (l + 16)^3 / 1560896
    sub2 = sub1 > EPSILON ? sub1 : l / KAPPA

    i = 0
    for c in 1:3, t in 0:1
        m = M[c, :]
        top1 = (284517 * m[1] - 94839 * m[3]) * sub2
        top2 = (838422 * m[3] + 769860 * m[2] + 731718 * m[1]) * l * sub2 - 769860 * t * l
        bottom = (632260 * m[3] - 126452 * m[2]) * sub2 + 126452 * t

        result[i+=1] = Line(
            slope = top1 / bottom,
            intercept = top2 / bottom
        )
    end

    return result
end


"""
For given lightness, returns the maximum chroma. Keeping the chroma value below
this number will ensure that for any hue, the color is within the Rgb gamut.
"""
function max_chroma(l)
    minimum(_distance_from_origin, get_bounds(l))
end

function max_chroma(l, h)
    hrad = deg2rad(h)
    # FIXME: Why does `length...` return negative values???
    minimum(get_bounds(l)) do bound
        len = _length_of_ray_until_intersect(hrad, bound)
        len >= 0 ? len : Inf
    end
end

# NOTE: The reference implementation defines `dot_product` here. Not necessary in Julia

"Used for rgb conversions"
function _from_linear(c)
    if c <= 0.0031308
        12.92 * c
    else
        1.055 * c^(1.0 / 2.4) - 0.055
    end
end

function _to_linear(c)
    if c > 0.04045
        ((c + 0.055) / 1.055)^2.4
    else
        c / 12.92
    end
end

function Rgb{Float64}(color::Xyz)
    Rgb{Float64}(_from_linear.(M * [color...])...)
end

function Xyz(color::Rgb{Float64})
    rgbl = _to_linear.([color...])
    Xyz((MINV * rgbl)...)
end

# NOTE: The reference implementation defines `yToL`/`lToY` here. Inlined instead

function Luv((; x, y, z)::Xyz)
    l = y <= EPSILON ? (y * KAPPA) : 116 * y^(1.0 / 3.0) - 16

    if l == 0
        Luv(0, 0, 0)
    else
        divider = x + 15 * y + 3 * z
        _u = 4 * x / divider
        _v = 9 * y / divider

        Luv(
            l,
            13 * l * (_u - REF_U),
            13 * l * (_v - REF_V),
        )
    end
end

function Xyz((; l, u, v)::Luv)
    if l == 0
        Xyz(0, 0, 0)
    else
        y = l <= 8 ? (l / KAPPA) : ((l + 16) / 116)^3

        _u = u / (13 * l) + REF_U
        _v = v / (13 * l) + REF_V

        Xyz(
            (y * 9 * _u) / (4 * _v),
            y,
            y * (12 - 3 * _u - 20 * _v) / (4 * _v)
        )
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

Rgb{Float64}(color::Lch) = color |> Luv |> Xyz |> Rgb{Float64}
Lch(color::Rgb{Float64}) = color |> Xyz |> Luv |> Lch

Rgb{Float64}(color::Hsluv) = color |> Lch |> Rgb{Float64}
Hsluv(color::Rgb{Float64}) = color |> Lch |> Hsluv

Rgb{Float64}(color::Hpluv) = color |> Lch |> Rgb{Float64}
Hpluv(color::Rgb{Float64}) = color |> Lch |> Hpluv

Rgb{Float64}(color::Rgb{UInt8}) = Rgb{Float64}([color...] ./ 255 ...)
Rgb{UInt8}(color::Rgb{Float64}) = Rgb{UInt8}(round.(UInt32, [color...] * 255)...)

Rgb{UInt8}(color::AbstractColor) = color |> Rgb{Float64} |> Rgb{UInt8}
Rgb{UInt8}(color::Rgb{UInt8}) = color

# FIXME: Do this without metaprogramming
for T in [:Hsluv, :Hpluv, :Lch, :Luv, :Xyz]
    @eval($T(color::Rgb{UInt8}) = color |> Rgb{Float64} |> $T)
end

Rgb(color::AbstractColor) = color |> Rgb{Float64}
Rgb(color::Rgb) = color


# Rgb{UInt8} <--> UInt32 (for IO)
Rgb{UInt8}(x::UInt32) = Rgb{UInt8}((x >> 16, x >> 8, x) .& 0xff...)
UInt32(c::Rgb{UInt8}) = (x = UInt32[c...]; x[1] << 16 + x[2] << 8 + x[3])

