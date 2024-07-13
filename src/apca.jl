module APCA

## Based on https://github.com/color-js/color.js/blob/v0.5.2/src/contrast/APCA.js
## Itself based on https://github.com/Myndex/apca-w3

using ..ColorUtils: AbstractColor
using ..RGBColors: RGB

# exponents
const normBG = 0.56
const normTXT = 0.57
const revTXT = 0.62
const revBG = 0.65

# clamps
const blkThrs = 0.022
const blkClmp = 1.414
const loClip = 0.1
const deltaYmin = 0.0005

# scalers
const scaleBoW = 1.14
const loBoWoffset = 0.027
const scaleWoB = 1.14
const loWoBoffset = 0.027

fclamp(Y) = Y >= blkThrs ? Y : Y + (blkThrs - Y) ^ blkClmp

linearize(val) = sign(val) * (abs(val) ^ 2.4)

"""
    get_contrast(background::RGB, foreground::RGB)

Calculate the contrast between a `background` and a `foreground` RGB colors
using the Accessible Perceptual Contrast Algorithm (APCA).

Note `get_contrast` is not symmetric.
"""
function get_contrast(background::RGB, foreground::RGB)
    # Calculates "screen luminance" with non-standard simple gamma EOTF
    # weights should be from CSS Color 4, not the ones here which are via Myndex and copied from Lindbloom
    p3_coefficients = [0.2289829594805780, 0.6917492625852380, 0.0792677779341829]

    (; r, g, b) = foreground
    lumFg = linearize.([r, g, b])' * p3_coefficients

    (; r, g, b) = background
    lumBg = linearize.([r, g, b])' * p3_coefficients

    # toe clamping of very dark values to account for flare
    Ytxt = fclamp(lumFg)
    Ybg = fclamp(lumBg)

    # why is this a delta, when Y is not perceptually uniform?
    # Answer: it is a noise gate, see
    # https://github.com/color-js/color.js/issues/208
    if abs(Ybg - Ytxt) < deltaYmin
        C = 0
    elseif Ybg > Ytxt
        # dark text on light background
        S = Ybg ^ normBG - Ytxt ^ normTXT
        C = S * scaleBoW
    else
        # light text on dark background
        S = Ybg ^ revBG - Ytxt ^ revTXT
        C = S * scaleWoB
    end

    if abs(C) < loClip
        Sapc = 0
    elseif C > 0
        # not clear whether Woffset is loBoWoffset or loWoBoffset
        # but they have the same value
        Sapc = C - loBoWoffset
    else
        Sapc = C + loBoWoffset
    end

    return Sapc * 100
end

get_contrast(bg::AbstractColor, fg::AbstractColor) = get_contrast(RGB(bg), RGB(fg))

end # module
