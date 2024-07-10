# TODO: Rename module
module TermColors

using ..ColorUtils: AbstractColor
using ..RGBColors: RGB24

"""
    Color8(n::UInt8)

An 8-bit color, representing one of 256 possible colors.
"""
struct Color8 <: AbstractColor
    n::UInt8
end

function _fill_16_colors!(colors)
    i = 0
    💡 = [false, true]
    for factor in [0x1, 0x0]
        for b in 💡, g in 💡, r in 💡
            colors[i+=1] = RGB24(
                r && (255 >>> factor) + factor,
                g && (255 >>> factor) + factor,
                b && (255 >>> factor) + factor,
            )
        end
    end

    # Dark white is lighter than light black
    colors[9] = colors[8]
    (; r, g, b) = colors[8]
    colors[8] = RGB24((r, g, b) .+ 0x40 ...)
    return
end

function _fill_color_cube!(colors)
    i = 0
    💡 = 0:5
    for r in 💡, g in 💡, b in 💡
        colors[i+=1] = RGB24(
            r != 0 && r * 40 + 55,
            g != 0 && g * 40 + 55,
            b != 0 && b * 40 + 55,
        )
    end
end

function _fill_gray_ramp!(colors)
    for gray in 0:23
        val = gray * 10 + 8
        colors[gray + 1] = RGB24(val, val, val)
    end
end

"""
    generate_xterm_colors()::Vector{RGB24}

Compute the vector of true color (RGB24) equivalents for xterm's 256 color palette (Color8).
"""
function generate_xterm_colors()::Vector{RGB24}
    colors = Vector(undef, 256)
    _fill_16_colors!(@view colors[1:16])
    _fill_color_cube!(@view colors[17:232])
    _fill_gray_ramp!(@view colors[233:256])
    return colors
end

function save_colors(path, colors)
    open(path, "w+") do f
        for c in colors
            println(f, c)
        end
    end
end

const XTERM_COLORS = generate_xterm_colors()

RGB24(color::Color8) = XTERM_COLORS[color.n]

end # module
