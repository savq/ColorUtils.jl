module ColorDistance

using ..ColorUtils: AbstractColor
using ..OklabColors: Oklab

"""
    get_distance(color1::Oklab, color2::Oklab)

Calculate the color difference ΔEOK of two colors in Oklab color space.
"""
function get_distance(c1::Oklab, c2::Oklab)
    @show c1, c2
    ΔL = c1.L - c2.L
    Δa = c1.a - c2.a
    Δb = c1.b - c2.b
    return sqrt(ΔL ^ 2 + Δa ^ 2 + Δb ^ 2)
end

get_distance(c1::AbstractColor, c2::AbstractColor) = distance(Oklab(c1), Oklab(c2))

end # module
