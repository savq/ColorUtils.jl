module Quantization

using ..ColorUtils: AbstractColor
using ..ColorDistance: get_distance
using ..OklabColors: Oklab
using ..TermColors: XTERM_COLORS

quantize(color, palette) = argmin(sample_color -> get_distance(color, sample_color), palette)

quantize_to_term_colors(color) = quantize(color, XTERM_COLORS)

# [RGB24(r + r << 4, g + g << 4, b + b << 4) for r in 0x0:0xF for g in 0x0:0xF for b in 0x0:0xF]

end
