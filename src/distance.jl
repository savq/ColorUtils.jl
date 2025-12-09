module ColorDistance

using ..ColorUtils: AbstractColor
using ..OklabColors: Oklab
using ..TermColors: XTERM_COLORS

"""
    get_distance(color1::Oklab, color2::Oklab)

Calculate the color difference ΔEOK of two colors in Oklab color space.
"""
get_distance(c1::Oklab, c2::Oklab) = hypot(c1.L - c2.L, c1.a - c2.a, c1.b - c2.b)

get_distance(c1::AbstractColor, c2::AbstractColor) = get_distance(Oklab(c1), Oklab(c2))


"""
    quantize(color, palette)

Return the index and the value of the `palette` color that best approximates `color`.
"""
quantize(color, palette) = argmin(idx_color -> get_distance(color, idx_color[2]), enumerate(palette))

quantize_to_term_colors(color) = quantize(color, XTERM_COLORS)

# [RGB24(r + r << 4, g + g << 4, b + b << 4) for r in 0x0:0xF for g in 0x0:0xF for b in 0x0:0xF]

end # module
