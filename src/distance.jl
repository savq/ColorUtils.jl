module ColorDistance

using ..ColorUtils: AbstractColor
using ..OklabColors: Oklab

"""
    get_distance(color1::Oklab, color2::Oklab)

Calculate the color difference ΔEOK of two colors in Oklab color space.
"""
function get_distance(c1::Oklab, c2::Oklab)
    return hypot(c1.L - c2.L, c1.a - c2.a, c1.b - c2.b)
end

get_distance(c1::AbstractColor, c2::AbstractColor) = get_distance(Oklab(c1), Oklab(c2))

end # module
