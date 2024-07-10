"""
Color conversion between color spaces, including RGB, Hsluv, Oklab, and Okhsl.
"""
module ColorUtils

export
    Okhsl,
    Oklab,
    RGB

include("./conversions/rgb.jl") # RGB <--> XYZ
using .RGBColors: RGB, XYZ

include("./conversions/oklab.jl") # Oklab <--> XYZ
using .OklabColors: Oklab

include("./conversions/okhsl.jl") # Okhsl <--> Oklab
using .OkhslColors: Okhsl

include("./types.jl")
export Rgb
export Hsluv
export Color256

include("./geometry.jl")
include("./hsluv.jl")

include("./io.jl")
export @rgb_str
export hex

include("./color8bit.jl")

end # module
