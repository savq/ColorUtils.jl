"""
Color conversion between color spaces, including RGB, Hsluv, Oklab, and Okhsl.
"""
module ColorUtils

export
    Hsluv,
    Okhsl,
    Oklab,
    Oklch,
    RGB,
    RGB24,
    get_contrast,
    get_distance,
    @rgb_str

"""
    AbstractColor

Every subtype of AbstractColor must have conversions to and from the XYZ color
space.
"""
abstract type AbstractColor end

struct XYZ <: AbstractColor
    x::Float64
    y::Float64
    z::Float64
end

include("./conversions/rgb.jl") # RGB24 <--> RGB <--> XYZ
using .RGBColors: RGB, RGB24

include("./conversions/oklab.jl") # Oklab <--> XYZ
using .OklabColors: Oklab, Oklch

include("./conversions/okhsl.jl") # Okhsl <--> Oklab
using .OkhslColors: Okhsl

include("./conversions/hsluv.jl") # Hsluv/Hpluv <--> Lch <--> Luv <--> XYZ
using .HsluvColors: Hsluv, Hpluv, Lch, Luv

include("./conversions/color8.jl") # Color8 <--> RGB24
using .TermColors: Color8

include("./apca.jl")
using .APCA: get_contrast

include("./distance.jl")
using .ColorDistance: get_distance

include("./quantization.jl")
using .Quantization: quantize, quantize_to_term_colors

include("./io.jl")
using .ColorIO: hex, @rgb_str

end # module
