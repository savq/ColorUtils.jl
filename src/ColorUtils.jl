"""
Color conversion between color spaces, including RGB, Hsluv, Oklab, and Okhsl.
"""
module ColorUtils

export
    Hsluv,
    Okhsl,
    Oklab,
    RGB,
    RGB24,
    @rgb_str

abstract type AbstractColor end

include("./conversions/rgb.jl") # RGB24 <--> RGB <--> XYZ
using .RGBColors: RGB, RGB24, XYZ

include("./conversions/oklab.jl") # Oklab <--> XYZ
using .OklabColors: Oklab

include("./conversions/okhsl.jl") # Okhsl <--> Oklab
using .OkhslColors: Okhsl

include("./conversions/hsluv.jl") # Hsluv/Hpluv <--> Lch <--> Luv <--> XYZ
using .HsluvColors: Hsluv, Hpluv, Lch, Luv

include("./conversions/color8.jl") # Color8 <--> RGB24
using .TermColors: Color8

include("./io.jl")
using .ColorIO: hex, @rgb_str

end # module
