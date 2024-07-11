"""
Convertions between RGB and XYZ color spaces.
"""
module RGBColors

using ..ColorUtils: AbstractColor, XYZ

"""
    RGB(r, g, b)

Create an RGB color from red, green, and blue values in range \$[0, 1]\$.
"""
struct RGB <: AbstractColor
    r::Float64
    g::Float64
    b::Float64
end

"""
    RGB24(r, g, b)

Create an RGB24 color from red, green, and blue values in range \$[0, 255]\$.
"""
struct RGB24 <: AbstractColor
    r::UInt8
    g::UInt8
    b::UInt8
end

## Use the same matrices as color.js
## https://github.com/color-js/color.js/blob/main/src/spaces/srgb-linear.js

const XYZ_from_RGB = [
    0.41239079926595934     0.357584339383878       0.1804807884018343
    0.21263900587151027     0.715168678767756       0.07219231536073371
    0.01933081871559182     0.11919477979462598     0.9505321522496607
]

const RGB_from_XYZ = [
     3.2409699419045226     -1.537383177570094      -0.4986107602930034
    -0.9692436362808796      1.8759675015077202      0.04155505740717559
     0.05563007969699366    -0.20397695888897652     1.0569715142428786
]

## transfer functions

"Convert a linear-light value in the range \$[0.0, 1.0]\$ to gamma corrected form."
function from_linear(a)
    return a <= 0.0031308 ? (12.92 * a) : (1.055 * a ^ (1.0 / 2.4) - 0.055)
end

function to_linear(a)
    return a <= 0.04045 ? (a / 12.92) : (((a + 0.055) / 1.055) ^ 2.4)
end

function RGB((; x, y, z)::XYZ)
    rgbl = RGB_from_XYZ * [x, y, z]
    return RGB(from_linear.(rgbl)...)
end

function XYZ((; r, g, b)::RGB)
    rgbl = to_linear.([r, g, b])
    return XYZ((XYZ_from_RGB * rgbl)...)
end

RGB(color::AbstractColor) = RGB(XYZ(color))


## RGB24

RGB((; r, g, b)::RGB24) = RGB([r, g, b] ./ 255 ...)
RGB24((; r, g, b)::RGB) = RGB24(round.(UInt8, [r, g, b] * 255)...)
RGB24(x::UInt32) = RGB24((x >> 16, x >> 8, x) .& 0xff...)

RGB24(xyz::XYZ) = RGB24(RGB(xyz))
XYZ(rgb::RGB24) = XYZ(RGB(rgb))

RGB24(color::AbstractColor) = RGB24(XYZ(color))

end # module
