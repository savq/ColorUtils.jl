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
    @test x.rgb   == RGB(parse(RGB24, x.hex))
    @test x.xyz   ≈ XYZ(x.rgb)
    @test x.luv   ≈ Luv(x.xyz)
    @test x.lch   ≈ Lch(x.luv)
    @test x.hsluv ≈ Hsluv(x.lch)
    @test x.hpluv ≈ Hpluv(x.lch)
    @assert x.hsluv ≈ Hsluv(parse(RGB24, x.hex))
    @assert x.hpluv ≈ Hpluv(parse(RGB24, x.hex))
end

@testset "Backward functions" for x in COLORS
    @test x.lch ≈ Lch(x.hsluv)
    @test x.lch ≈ Lch(x.hpluv)
    @test x.luv ≈ Luv(x.lch)
    @test x.xyz ≈ XYZ(x.luv)
    @test x.rgb ≈ RGB(x.xyz)

    @test x.hex == hex(x.rgb)
    @test x.hex == hex(x.hsluv)
    @test x.hex == hex(x.hpluv)
end
