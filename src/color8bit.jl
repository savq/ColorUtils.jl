"""
    generate_xterm_colors()::Vector{URgb}

Compute the vector of true color (RGB) equivalents for xterm's 256 color palette (Color256).
"""
function generate_xterm_colors()::Vector{URgb}
    colors = Vector(undef, 256)
    _fill_16_colors!(@view colors[1:16])
    _fill_color_cube!(@view colors[17:232])
    _fill_gray_ramp!(@view colors[233:256])
    return colors
end

function _fill_16_colors!(colors)
    i = 0
    💡 = [false, true]
    for factor in [0x1, 0x0]
        for b in 💡, g in 💡, r in 💡
            colors[i+=1] = URgb(
                r && (255 >>> factor) + factor,
                g && (255 >>> factor) + factor,
                b && (255 >>> factor) + factor,
            )
        end
    end

    # Dark white is lighter than light black
    colors[9] = colors[8]
    colors[8] = URgb([colors[8]...] .+ 0x40 ...)
    return
end

function _fill_color_cube!(colors)
    i = 0
    💡 = 0:5
    for r in 💡, g in 💡, b in 💡
        colors[i+=1] = URgb(
            r != 0 && r * 40 + 55,
            g != 0 && g * 40 + 55,
            b != 0 && b * 40 + 55,
        )
    end
end

function _fill_gray_ramp!(colors)
    for gray in 0:23
        val = gray * 10 + 8
        colors[gray + 1] = URgb(val, val, val)
    end
end

const XTERM_COLORS = generate_xterm_colors()

function save_colors(path, colors)
    open(path, "w+") do f
        for c in colors
            println(f, c)
        end
    end
end
