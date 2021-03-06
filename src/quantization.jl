"""
    generate_xterm_colors()::Vector{URgb}

Compute the array of true color (URgb) equivalents for xterm's 256 color palette (Color256).
"""
function generate_xterm_colors()::Vector{URgb}
    colors = Vector(undef, 256)
    _fill_16_colors!(colors)
    _fill_color_cube!(colors)
    _fill_gray_ramp!(colors)
    return colors
end

function _fill_16_colors!(colors)
    i = 0
    for factor in [1, 0]
        ð¡ = [false, true]
        for b in ð¡, g in ð¡, r in ð¡
            colors[i+=1] = URgb(
                r ? (255 >>> factor) + factor : 0,
                g ? (255 >>> factor) + factor : 0,
                b ? (255 >>> factor) + factor : 0
            )
        end
    end

    colors[9] = colors[8]
    colors[8] = URgb([colors[8]...] .+ 64 ...)
    return
end

function _fill_color_cube!(colors)
    i = 16
    ð¡ = 1:5
    for r in ð¡, g in ð¡, b in ð¡
        colors[i+=1] = URgb(
            r == 0 ? 0 : r * 40 + 55,
            g == 0 ? 0 : g * 40 + 55,
            b == 0 ? 0 : b * 40 + 55
        )
    end
end

function _fill_gray_ramp!(colors)
    colors[233:256] = map(0:23) do gray
        val = gray * 10 + 8
        URgb(val, val, val)
    end
    return
end

_dist(p::URgb, q::URgb) = âsum((Float64[p...] .- Float64[q...]) .^ 2.0)
_dist(p::URgb) = Base.Fix2(_dist, p)

const XTERM_COLORS = generate_xterm_colors()

quantize(color::URgb, palette::Vector{URgb}=XTERM_COLORS) = argmin(_dist(color), palette)

