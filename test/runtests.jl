using ColorUtils: AbstractColor, RGB, RGB24, XYZ, Hsluv, Hpluv, Luv, Lch, hex

using Test

@testset "HSLuv tests" begin
    include("./fetch_data_hsluv.jl")
    include("./hsluv.jl")
end

# TODO: Add tests for other color spaces
