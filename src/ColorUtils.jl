"""
Utilities for 8-bit/256 and 24-bit/RGB colors, as well as HSLuv
conversion utilities. See the HSLuv reference implementation
for details: https://github.com/hsluv/hsluv
"""
module ColorUtils

import Core: UInt32
import Base: iterate, print, show, parse

include("./color_types.jl")     # struct definitions
export AbstractColor

export Rgb
export Hsluv
export Hpluv

export Lch
export Luv
export Xyz

export Color256

include("./io.jl")
export @rgb_str

include("./color8bit.jl")

include("./geometry.jl")
include("./conversions.jl")
export hex

end # module
