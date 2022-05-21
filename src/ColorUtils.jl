"""
Utilities for 8-bit/256 and 24-bit/RGB colors.
"""
module ColorUtils

import Core: UInt32
import Base: iterate, print, show, parse

include("./TermColors.jl")
export Color256
export ColorRGB
export @rgb_str
export quantize

include("./HsluvColors.jl")

end # module
