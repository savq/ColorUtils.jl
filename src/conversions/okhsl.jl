"""
Convertions between Okhsl and Oklab color spaces.
"""
module OkhslColors

using ..ColorUtils: AbstractColor
using ..OklabColors: Oklab, XYZ_from_LMS, LMS_from_Lab
using ..RGBColors: RGB, XYZ, RGB_from_XYZ

"""
    Okhsl(h, s, l)

Create an Okhsl color.
"""
struct Okhsl <: AbstractColor
    "`Okhsl.h` is the hue in range \$[0, 360]\$"
    h::Float64
    "`Okhsl.s` is the saturation in range \$[0, 100]\$"
    s::Float64
    "`Okhsl.l` is the lightness in range \$[0, 100]\$"
    l::Float64
end

# TODO: REMOVE?
const RGB_from_LMS = RGB_from_XYZ * XYZ_from_LMS


#= Lightness Estimate =#

const K1 = 0.206
const K2 = 0.03
const K3 = (1.0 + K1) / (1.0 + K2)

function toe(L)
    Lr = 0.5 * (K3 * L - K1 + sqrt(((K3 * L - K1) ^ 2) + (4 * K2 * K3 * L)))
    return Lr
end

function toe_inv(Lr)
    L = (Lr * (Lr + K1)) / (K3 * (Lr + K2))
    return L
end


#= sRGB Gamut Intersection =#

## Finds the maximum saturation possible for a given hue that fits in sRGB
## Saturation here is defined as S = C/L
## a and b must be normalized so a^2 + b^2 == 1
function compute_max_saturation(a, b)
    # Max saturation will be when one of r, g or b goes below zero.

    # Select different coefficients depending on which component goes below zero first
    if [-1.88170328, -0.80936493]' * [a, b] > 1
        # Red component
        k = [+1.19086277, +1.76576728, +0.59662641, +0.75515197, +0.56771245]
        w_lms = RGB_from_LMS[1, :]
    elseif [1.81444104, -1.19445276]' * [a, b] > 1
        # Green component
        k = [+0.73956515, -0.45954404, +0.08285427, +0.12541070, +0.14503204]
        w_lms = RGB_from_LMS[2, :]
    else
        # Blue component
        k = [+1.35733652, -0.00915799, -1.15130210, -0.50559606, +0.00692167]
        w_lms = RGB_from_LMS[3, :]
    end

    # Approximate max saturation using a polynomial
    sat = k' * [1, a, b, a ^ 2, a * b]

    # Do one step Halley's method to get closer
    # this gives an error less than 10e6, except for some blue hues where the dS/dh is close to infinite
    # this should be sufficient for most applications, otherwise do two/three steps
    k_lms = LMS_from_Lab[:, 2:3] * [a, b]

    lms_ = 1 .+ sat .* k_lms
    lms = lms_ .^ 3
    lmsds = 3 * k_lms .* (lms_ .^ 2)
    lmsds2 = 6 * (k_lms .^ 2) .* lms_

    f = w_lms' * lms
    f1 = w_lms' * lmsds
    f2 = w_lms' * lmsds2

    sat = sat - f * f1 / (f1 * f1 - 0.5 * f * f2)

    return sat
end

## Find L_cusp and C_cusp for a given hue.
## a and b must be normalized so a^2 + b^2 == 1
function find_cusp(a, b)
    # Find the maximum saturation (saturation `S = C/L`)
    s_cusp = compute_max_saturation(a, b)

    # Convert to linear sRGB to find the first point where at least one of r, g or b >= 1
    # NOTE(savq): We don't call RGB because that whould unlinearize the values.
    (; x, y, z) = XYZ(Oklab(1, s_cusp * a, s_cusp * b))
    rgb_linear = RGB_from_XYZ * [x, y, z]
    l_cusp = cbrt(1 / maximum(rgb_linear))
    c_cusp = l_cusp * s_cusp

    return (l_cusp, c_cusp)
end

## Find intersection of the line defined by:
## L = L0 * (1 - t) + t * L1
## C = t * C1
## a and b must be normalized so a^2 + b^2 == 1
function find_gamut_intersection(a, b, l1, c1, l0, cusp=find_cusp(a, b))
    (l_cusp, c_cusp) = cusp

    # Find the intersection for upper and lower half separately
    local t
    if ((l1 - l0) * c_cusp - (l_cusp - l0) * c1) <= 0
        # Lower half
        t = c_cusp * l0 / (c1 * l_cusp + c_cusp * (l0 - l1))
    else
        # Upper half

        # First intersect with triangle
        t = c_cusp * (l0 - 1) / (c1 * (l_cusp - 1) + c_cusp * (l0 - l1))

        # Then one step Halley's method
        dl = l1 - l0
        dc = c1

        k_lms = LMS_from_Lab[:, 2:3] * [a, b]

        lmsdt_ = dl .+ dc .* k_lms

        # If higher accuracy is required, 2 or 3 iterations of the following block can be used
        begin
            l = l0 * (1 - t) + t * l1
            c = t * c1

            lms_ = l .+ c .* k_lms
            lms = lms_ .^ 3
            lmsdt = 3 .* lmsdt_ .* (lms_ .^ 2)
            lmsdt2 = 6 .* (lmsdt_ .^ 2) .* lms_

            ## NOTE: this part is very different from the reference implementation
            w = hcat(lms, lmsdt, lmsdt2)
            u(x) = x[2] / (x[2] * x[2] - 0.5 * (x[1] - 1) * x[3])

            r = RGB_from_LMS[1, :]' * w
            ur = u(r)
            tr = -r[1] * ur

            g = RGB_from_LMS[2, :]' * w
            ug = u(g)
            tg = -g[1] * ug

            b = RGB_from_LMS[3, :]' * w
            ub = u(b)
            tb = -b[1] * ub

            tr = (ur >= 0) ? tr : Inf
            tg = (ug >= 0) ? tg : Inf
            tb = (ub >= 0) ? tb : Inf

            t += min(tr, tg, tb)
        end
    end

    return t
end


#= Chroma values =#

function to_ST(a_, b_, cusp=find_cusp(a_, b_))
    (l, c) = cusp
    return (c / l, c / (1 - l))
end

## Returns a smooth approximation of the location of the cusp
## This polynomial was created by an optimization process
## It has been designed so that S_mid < S_max and T_mid < T_max
function get_ST_mid(a_, b_)
    s = 0.11516993 + 1 / (
        7.44778970 + 4.15901240 * b_ + a_ * (
            -2.19557347 + 1.75198401 * b_ + a_ * (
                -2.13704948 - 10.02301043 * b_ + a_ * (
                    -4.24894561 + 5.38770819 * b_ + 4.69891013 * a_
                )
            )
        )
    )
    t = 0.11239642 + 1 / (
        1.61320320 - 0.68124379 * b_ + a_ * (
            0.40370612 + 0.90148123 * b_ + a_ * (
                -0.27087943 + 0.61223990 * b_ + a_ * (
                    0.00299215 - 0.45399568 * b_ - 0.14661872 * a_
                )
            )
        )
    )
    return (s, t)
end

function get_Cs(l, a_, b_)
    cusp = find_cusp(a_, b_)

    c_max = find_gamut_intersection(a_, b_, l, 1, l, cusp)

    (s_max, t_max) = to_ST(a_, b_, cusp)
    (s_mid, t_mid) = get_ST_mid(a_, b_)

    # Scale factor to compensate for the curved part of gamut shape
    k = c_max / min(l * s_max, (1 - l) * t_max)

    c_mid = let
        c_a = l * s_mid
        c_b = (1 - l) * t_mid
        # Use a soft minimum function, instead of a sharp triangle shape to get a smooth value for chroma.
        0.9 * k * fourthroot(1 / (1 / (c_a ^ 4) + 1 / (c_b ^ 4)))
    end

    c_0 = let
        # for c_0, the shape is independent of hue, so ST are constant.
        # Values picked to roughly be the average values of ST.
        c_a = l * 0.4
        c_b = (1 - l) * 0.8
        # Use a soft minimum function, instead of a sharp triangle shape to get a smooth value for chroma.
        sqrt(1 / (1 / (c_a ^ 2) + 1 / (c_b ^ 2)))
    end

    return (c_0, c_mid, c_max)
end


#= Conversions =#

function Oklab((; h, s, l)::Okhsl)
    (h, s, l) = (h / 360, s / 100, l / 100)

    if l == 1.0 || l == 0.0
        return Oklab(l, 0, 0)
    end

    L = toe_inv(l)
    a_ = cospi(2 * h)
    b_ = sinpi(2 * h)

    (c_0, c_mid, c_max) = get_Cs(L, a_, b_)

    # Interpolate the three values for C so that:
    # At s=0: dC/ds = c_0, C=0
    # At s=0.8: C=c_mid
    # At s=1.0: C=c_max

    mid = 0.8
    mid_inv = 1.25

    if s < mid
        t = mid_inv * s
        k0 = 0
        k1 = mid * c_0
        k2 = 1 - (k1 / c_mid)
    else
        t = 5 * (s - mid)
        k0 = c_mid
        k1 = ((1 - mid) * (c_mid ^ 2) * (mid_inv ^ 2)) / c_0
        k2 = 1 - (k1 / (c_max - c_mid))
    end

    c = k0 + t * k1 / (1 - k2 * t)
    a = c * a_
    b = c * b_

    return Oklab(L, a, b)
end

function Okhsl((; L, a, b)::Oklab)
    s = 0.0
    l = toe(L)

    c = sqrt(a ^ 2 + b ^ 2)
    h = 0.5 + atan(-b, -a) / (2 * pi)

    if l != 0.0 && l != 1.0 && c != 0
        a_ = a / c
        b_ = b / c

        (c_0, c_mid, c_max) = get_Cs(L, a_, b_)

        # Inverse of the interpolation Oklab(::Okhsl)
        mid = 0.8
        mid_inv = 1.25

        if c < c_mid
            k0 = 0
            k1 = mid * c_0
            k2 = 1 - (k1 / c_mid)

            t = (c - k0) / (k1 + k2 * (c - k0))
            s = t * mid
        else
            k0 = c_mid
            k1 = (1 - mid) * (c_mid ^ 2) * (mid_inv ^ 2) / c_0
            k2 = 1 - k1 / (c_max - c_mid)

            t = (c - k0) / (k1 + k2 * (c - k0))
            s = mid + (1 - mid) * t
        end
    end

    let (h, s, l) = round.((h * 360, s * 100, l * 100))
        return Okhsl(h, s, l)
    end
end

Okhsl(rgb::RGB) = rgb |> Oklab |> Okhsl
RGB(hsl::Okhsl) = hsl |> Oklab |> RGB

Okhsl(color::AbstractColor) = color |> RGB |> Okhsl

end # module
