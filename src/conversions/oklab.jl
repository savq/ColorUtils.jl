"""
Convertions between Oklab and XYZ color spaces.
"""
module OklabColors

using ..ColorUtils: AbstractColor, XYZ

"""
    Oklab(L, a, b)

Create an Oklab color.
"""
struct Oklab <: AbstractColor
    "`Oklab.L` is the perceived lightness, in range \$[0, 1]\$."
    L::Float64
    "`Oklab.a` is the distance along the green/red axis, in range \$[-0.4, 0.4]\$."
    a::Float64
    "`Oklab.b` is the distance along the blue/yellow axis, in range \$[-0.4, 0.4]\$."
    b::Float64
end

"""
    Oklch(L, C, h)

Create an Oklch color (a polar representation of Oklab).
"""
struct Oklch <: AbstractColor
    "`Oklab.L` is the perceived lightness, in range \$[0, 1]\$. Same as Oklab."
    L::Float64
    "`Oklab.C` is the chroma, in range \$[0, 0.4]\$."
    C::Float64
    "`Oklab.h` is the hue, an angle in range \$[0, 360]\$."
    h::Int64
end

const LMS_from_XYZ = [
    0.8190224379967030      0.3619062600528904      -0.1288737815209879
    0.0329836539323885      0.9292868615863434       0.0361446663506424
    0.0481771893596242      0.2642395317527308       0.6335478284694309
]

const XYZ_from_LMS = [
     1.2268798758459243     -0.5578149944602171      0.2813910456659647
    -0.0405757452148008      1.1122868032803170     -0.0717110580655164
    -0.0763729366746601     -0.4214933324022432      1.5869240198367816
]

const Lab_from_LMS = [
    0.2104542683093140       0.7936177747023054     -0.0040720430116193
    1.9779985324311684      -2.4285922420485799      0.4505937096174110
    0.0259040424655478       0.7827717124575296     -0.8086757549230774
]

const LMS_from_Lab = [
    1.0000000000000000       0.3963377773761749      0.2158037573099136
    1.0000000000000000      -0.1055613458156586     -0.0638541728258133
    1.0000000000000000      -0.0894841775298119     -1.2914855480194092
]

function Oklab((; x, y, z)::XYZ)
    lms = LMS_from_XYZ * [x, y, z]
    lms′ = cbrt.(lms)
    Lab = Lab_from_LMS * lms′
    return Oklab(Lab...)
end

function XYZ((; L, a, b)::Oklab)
    lms′ = LMS_from_Lab * [L, a, b]
    lms = lms′ .^ 3
    xyz = XYZ_from_LMS * lms
    return XYZ(xyz...)
end

function Oklab((; L, C, h)::Oklch)
    C = C < 0 ? 0 : C
    a = C * cospi(h / 180)
    b = C * sinpi(h / 180)
    return Oklab(L, a, b)
end

function Oklch((; L, a, b)::Oklab)
    C = sqrt(a ^ 2 + b ^ 2)
    h = 0.5 + atan(-b, -a) / (2 * pi)
    return Oklch(L, C, round(Int, h * 360))
end

Oklch(xyz::XYZ) = Oklch(Oklab(xyz))
XYZ(lch::Oklch) = XYZ(Oklab(lch))

Oklab(color::AbstractColor) = Oklab(XYZ(color))
Oklch(color::AbstractColor) = Oklch(XYZ(color))

end # module
