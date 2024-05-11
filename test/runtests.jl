include("../src/ColorUtils.jl")
using .ColorUtils: AbstractColor, Rgb, Xyz, Luv, Lch, Hsluv, Hpluv, hex

include("./fetch.jl")

using Test

const MAXDIFF = 0.0000000001
const MAXRELDIFF = 0.000000001

const COLORS = get_data() # See ./fetch.jl

function Base.isapprox(x::C, y::C) where {C <: AbstractColor}
    mapreduce(&, fieldnames(C)) do field
        isapprox(
            getproperty(x, field),
            getproperty(y, field),
            atol=MAXDIFF,
            rtol=MAXRELDIFF,
        )
    end
end

@testset "Forward functions" for x in COLORS
    # forward functions
    @test x.rgb   == parse(Rgb{Float64}, x.hex)
    @test x.xyz   ≈ Xyz(x.rgb)
    @test x.luv   ≈ Luv(x.xyz)
    @test x.lch   ≈ Lch(x.luv)
    @test x.hsluv ≈ Hsluv(x.lch)
    @test x.hpluv ≈ Hpluv(x.lch)
    @assert x.hsluv ≈ Hsluv(parse(Rgb{Float64}, x.hex))
    @assert x.hpluv ≈ Hpluv(parse(Rgb{Float64}, x.hex))
end

@testset "Backward functions" for x in COLORS
    @test x.lch ≈ Lch(x.hsluv)
    @test x.lch ≈ Lch(x.hpluv)
    @test x.luv ≈ Luv(x.lch)
    @test x.xyz ≈ Xyz(x.luv)
    @test x.rgb ≈ Rgb{Float64}(x.xyz)

    @test x.hex == hex(x.rgb)
    @test x.hex == hex(x.hsluv)
    @test x.hex == hex(x.hpluv)
end

