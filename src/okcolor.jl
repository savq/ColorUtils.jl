"""
A partial port of Björn Ottosson's OK family of color spaces; including OKLab, OkHsl.
"""
module OkColor

export
    srgb_to_okhsl,
    okhsl_to_srgb,
    oklab_to_linear_srgb,
    linear_srgb_to_oklab


srgb_transfer_function(a) = a <= 0.0031308 ? 12.92 * a : 1.055 * a ^ (1.0 / 2.4) - 0.055

srgb_transfer_function_inv(a) = a > 0.04045 ? ((a + 0.055) / 1.055) ^ 2.4 : a / 12.92

function linear_srgb_to_oklab((; r, g, b))
    srgb_to_lms = [
        0.4122214708 0.5363325363 0.0514459929
        0.2119034982 0.6806995451 0.1073969566
        0.0883024619 0.2817188376 0.6299787005
    ]
    lms′_to_Lab = [
        0.2104542553 +0.7936177850 -0.0040720468
        1.9779984951 -2.4285922050 +0.4505937099
        0.0259040371 +0.7827717662 -0.8086757660
    ]
    lms = srgb_to_lms * [r, g, b]
    lms′ = cbrt.(lms)
    return lms′_to_Lab * lms′
end

function oklab_to_linear_srgb((; L, a, b))
    Lab_to_lms′ = [
        1.0 +0.3963377774 +0.2158037573
        1.0 -0.1055613458 -0.0638541728
        1.0 -0.0894841775 -1.2914855480
    ]
    lms_to_srgb = [
        +4.0767416621 -3.3077115913 +0.2309699292
        -1.2684380046 +2.6097574011 -0.3413193965
        -0.0041960863 -0.7034186147 +1.7076147010
    ]
    lms′ = Lab_to_lms′ * [L, a, b]
    lms = lms′ .^ 3
    r, g, b = lms_to_srgb * lms
    return (; r, g, b)
end

function toe(x)
    k_1 = 0.206
    k_2 = 0.03
    k_3 = (1 + k_1) / (1 + k_2)
    return 0.5 * (k_3 * x - k_1 +
            sqrt((k_3 * x - k_1) * (k_3 * x - k_1) + 4 * k_2 * k_3 * x))
end

function toe_inv(x)
    k_1 = 0.206
    k_2 = 0.03
    k_3 = (1 + k_1) / (1 + k_2)
    return (x * x + k_1 * x) / (k_3 * (x + k_2))
end

# Finds the maximum saturation possible for a given hue that fits in sRGB
# Saturation here is defined as S = C/L
# a and b must be normalized so a^2 + b^2 == 1
function compute_max_saturation(a, b)
    # Max saturation will be when one of r, g or b goes below zero.

    # Select different coefficients depending on which component goes below zero first
    if -1.88170328 * a - 0.80936493 * b > 1
        # Red component
        k0 = +1.19086277
        k1 = +1.76576728
        k2 = +0.59662641
        k3 = +0.75515197
        k4 = +0.56771245
        wl = +4.0767416621
        wm = -3.3077115913
        ws = +0.2309699292
    elseif 1.81444104 * a - 1.19445276 * b > 1
        # Green component
        k0 = +0.73956515
        k1 = -0.45954404
        k2 = +0.08285427
        k3 = +0.12541070
        k4 = +0.14503204
        wl = -1.2684380046
        wm = +2.6097574011
        ws = -0.3413193965
    else
        # Blue component
        k0 = +1.35733652
        k1 = -0.00915799
        k2 = -1.15130210
        k3 = -0.50559606
        k4 = +0.00692167
        wl = -0.0041960863
        wm = -0.7034186147
        ws = +1.7076147010
    end

    # Approximate max saturation using a polynomial:
    S = k0 + k1 * a + k2 * b + k3 * a * a + k4 * a * b

    # Do one step Halley's method to get closer
    # this gives an error less than 10e6, except for some blue hues where the dS/dh is close to infinite
    # this should be sufficient for most applications, otherwise do two/three steps
    k_l = +0.3963377774 * a + 0.2158037573 * b
    k_m = -0.1055613458 * a - 0.0638541728 * b
    k_s = -0.0894841775 * a - 1.2914855480 * b

    l_ = 1 + S * k_l
    m_ = 1 + S * k_m
    s_ = 1 + S * k_s

    l = l_ * l_ * l_
    m = m_ * m_ * m_
    s = s_ * s_ * s_

    l_dS = 3 * k_l * l_ * l_
    m_dS = 3 * k_m * m_ * m_
    s_dS = 3 * k_s * s_ * s_

    l_dS2 = 6 * k_l * k_l * l_
    m_dS2 = 6 * k_m * k_m * m_
    s_dS2 = 6 * k_s * k_s * s_

    f = wl * l + wm * m + ws * s
    f1 = wl * l_dS + wm * m_dS + ws * s_dS
    f2 = wl * l_dS2 + wm * m_dS2 + ws * s_dS2

    S = S - f * f1 / (f1 * f1 - 0.5 * f * f2)

    return S
end

"""
Find L_cusp and C_cusp for a given hue.
a and b must be normalized so a^2 + b^2 == 1
"""
function find_cusp(a, b)
    # First, find the maximum saturation (saturation S = C/L)
    S_cusp = compute_max_saturation(a, b)

    # Convert to linear sRGB to find the first point where at least one of r, g or b >= 1:
    rgb_at_max = oklab_to_linear_srgb((L = 1, a = S_cusp * a, b = S_cusp * b))
    L_cusp = cbrt(1 / maximum(rgb_at_max))
    C_cusp = L_cusp * S_cusp

    return [L_cusp, C_cusp]
end

"""
Find intersection of the line defined by:
L = L0 * (1 - t) + t * L1;
C = t * C1;
a and b must be normalized so a^2 + b^2 == 1
"""
function find_gamut_intersection(a, b, L1, C1, L0, cusp=nothing)
    if isnothing(cusp)
        # Find the cusp of the gamut triangle
        cusp = find_cusp(a, b)
    end

    # Find the intersection for upper and lower half separately
    if (L1 - L0) * cusp[2] - (cusp[1] - L0) * C1 <= 0
        # Lower half
        t = cusp[2] * L0 / (C1 * cusp[1] + cusp[2] * (L0 - L1))
    else
        # Upper half

        # First intersect with triangle
        t = cusp[2] * (L0 - 1) / (C1 * (cusp[1] - 1) + cusp[2] * (L0 - L1))

        # Then one step Halley's method
        dL = L1 - L0
        dC = C1

        k_l = +0.3963377774 * a + 0.2158037573 * b
        k_m = -0.1055613458 * a - 0.0638541728 * b
        k_s = -0.0894841775 * a - 1.2914855480 * b

        l_dt = dL + dC * k_l
        m_dt = dL + dC * k_m
        s_dt = dL + dC * k_s

        # If higher accuracy is required, 2 or 3 iterations of the following block can be used
        L = L0 * (1 - t) + t * L1
        C = t * C1

        l_ = L + C * k_l
        m_ = L + C * k_m
        s_ = L + C * k_s

        l = l_ ^ 3
        m = m_ ^ 3
        s = s_ ^ 3

        ldt = 3 * l_dt * l_ * l_
        mdt = 3 * m_dt * m_ * m_
        sdt = 3 * s_dt * s_ * s_

        ldt2 = 6 * l_dt * l_dt * l_
        mdt2 = 6 * m_dt * m_dt * m_
        sdt2 = 6 * s_dt * s_dt * s_

        r = 4.0767416621 * l - 3.3077115913 * m + 0.2309699292 * s - 1
        r1 = 4.0767416621 * ldt - 3.3077115913 * mdt + 0.2309699292 * sdt
        r2 = 4.0767416621 * ldt2 - 3.3077115913 * mdt2 + 0.2309699292 * sdt2

        u_r = r1 / (r1 * r1 - 0.5 * r * r2)
        t_r = -r * u_r

        g = -1.2684380046 * l + 2.6097574011 * m - 0.3413193965 * s - 1
        g1 = -1.2684380046 * ldt + 2.6097574011 * mdt - 0.3413193965 * sdt
        g2 = -1.2684380046 * ldt2 + 2.6097574011 * mdt2 - 0.3413193965 * sdt2

        u_g = g1 / (g1 * g1 - 0.5 * g * g2)
        t_g = -g * u_g

        b = -0.0041960863 * l - 0.7034186147 * m + 1.7076147010 * s - 1
        b1 = -0.0041960863 * ldt - 0.7034186147 * mdt + 1.7076147010 * sdt
        b2 = -0.0041960863 * ldt2 - 0.7034186147 * mdt2 + 1.7076147010 * sdt2

        u_b = b1 / (b1 * b1 - 0.5 * b * b2)
        t_b = -b * u_b

        t_r = u_r >= 0 ? t_r : 10e5
        t_g = u_g >= 0 ? t_g : 10e5
        t_b = u_b >= 0 ? t_b : 10e5

        t += min(t_r, t_g, t_b)
    end

    return t
end

function get_ST_max(a_, b_, cusp = nothing)
    if isnothing(cusp)
        cusp = find_cusp(a_, b_)
    end
    L, C = cusp
    return [C / L, C / (1 - L)]
end

function get_ST_mid(a_, b_)
  S = 0.11516993 + 1 / (
        +7.44778970 + 4.15901240 * b_ +
        a_ * (-2.19557347 + 1.75198401 * b_ +
            a_ * (-2.13704948 - 10.02301043 * b_ +
                a_ * (-4.24894561 + 5.38770819 * b_ + 4.69891013 * a_)))
      )

  T = 0.11239642 + 1 / (
        +1.61320320 - 0.68124379 * b_ +
        a_ * (+0.40370612 + 0.90148123 * b_ +
            a_ * (-0.27087943 + 0.61223990 * b_ +
                a_ * (+0.00299215 - 0.45399568 * b_ - 0.14661872 * a_)))
      )

  return [S, T]
end

function get_Cs(L, a_, b_)
    cusp = find_cusp(a_, b_)

    C_max = find_gamut_intersection(a_, b_, L, 1, L, cusp)
    ST_max = get_ST_max(a_, b_, cusp)

    S_mid = 0.11516993 + 1 / (
        +7.44778970 + 4.15901240 * b_ +
            a_ * (-2.19557347 + 1.75198401 * b_ +
                a_ * (-2.13704948 - 10.02301043 * b_ +
                    a_ * (-4.24894561 + 5.38770819 * b_ + 4.69891013 * a_)))
    )

    T_mid = 0.11239642 + 1 / (
        +1.61320320 - 0.68124379 * b_ +
            a_ * (+0.40370612 + 0.90148123 * b_ +
                a_ * (-0.27087943 + 0.61223990 * b_ +
                    a_ * (+0.00299215 - 0.45399568 * b_ - 0.14661872 * a_)))
    )

    k = C_max / min(L * ST_max[1], (1 - L) * ST_max[2])

    C_mid = let
        C_a = L * S_mid
        C_b = (1 - L) * T_mid

        0.9 * k * fourthroot(1 / (1 / (C_a ^ 4) + 1 / (C_b ^ 4)))
    end

    C_0 = let
        C_a = L * 0.4
        C_b = (1 - L) * 0.8

        sqrt(1 / (1 / (C_a * C_a) + 1 / (C_b * C_b)))
    end

    return [C_0, C_mid, C_max]
end

function okhsl_to_srgb((; h, s, l))
    let
        (h, s, l) = (h / 360, s / 100, l / 100)
        if l == 1
            return (; r = 255, g = 255, b = 255)
        elseif l == 0
            return (; r = 0, g = 0, b = 0)
        end

        a_ = cos(2π * h)
        b_ = sin(2π * h)
        L = toe_inv(l)

        Cs = get_Cs(L, a_, b_)
        C_0 = Cs[1]
        C_mid = Cs[2]
        C_max = Cs[3]

        if s < 0.8
            t = 1.25 * s
            k_0 = 0
            k_1 = 0.8 * C_0
            k_2 = 1 - k_1 / C_mid
        else
            t = 5 * (s - 0.8)
            k_0 = C_mid
            k_1 = 0.2 * C_mid * C_mid * 1.25 * 1.25 / C_0
            k_2 = 1 - k_1 / (C_max - C_mid)
        end

        C = k_0 + t * k_1 / (1 - k_2 * t)

        # If we would only use one of the Cs:
        # C = s * C_0;
        # C = s * 1.25 * C_mid;
        # C = s * C_max;

        r, g, b = oklab_to_linear_srgb((; L, a = C * a_, b = C * b_))
        r, g, b = round.(255 .* srgb_transfer_function.([r, g, b]))
        return (; r, g, b)
    end
end

function srgb_to_okhsl((; r, g, b))
    r, g, b = srgb_transfer_function_inv.([r, g, b] ./ 255)
    lab = linear_srgb_to_oklab((; r, g, b))

    C = sqrt(lab[2] ^ 2 + lab[3] ^ 2)
    a_ = lab[2] / C
    b_ = lab[3] / C

    L = lab[1]
    h = 0.5 + 0.5 * atan(-lab[3], -lab[2]) / π

    Cs = get_Cs(L, a_, b_)
    C_0 = Cs[1]
    C_mid = Cs[2]
    C_max = Cs[3]

    if C < C_mid
        k_0 = 0
        k_1 = 0.8 * C_0
        k_2 = 1 - k_1 / C_mid

        t = (C - k_0) / (k_1 + k_2 * (C - k_0))
        s = t * 0.8
    else
        k_0 = C_mid
        k_1 = 0.2 * C_mid * C_mid * 1.25 * 1.25 / C_0
        k_2 = 1 - k_1 / (C_max - C_mid)

        t = (C - k_0) / (k_1 + k_2 * (C - k_0))
        s = 0.8 + 0.2 * t
    end

    l = toe(L)
    let
        (h, s, l) = round.((h * 360, s * 100, l * 100))
        return (; h, s, l)
    end
end

end # module
