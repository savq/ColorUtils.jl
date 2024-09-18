# Script to read the JSON snapshot used for testing

import JSON3

"URL for the JSON snapshot of the color space generated from the reference implementation."
const URL = "https://raw.githubusercontent.com/hsluv/hsluv/master/snapshots/snapshot-rev4.json"

function fetch_data(path)
    run(pipeline(`curl $URL`, stdout=path))
end

function read_data(path)
    open(JSON3.read, path, "r")
end

function clean_data(json)
    vec = Vector{NamedTuple}(undef, length(json))
    i = 0
    for (hex, v) in json
        vec[i+=1] = (
            hex = String(hex),
            hpluv = Hpluv(v[:hpluv]...),
            hsluv = Hsluv(v[:hsluv]...),
            lch   = Lch(v[:lch]...),
            luv   = Luv(v[:luv]...),
            rgb   = RGB(v[:rgb]...),
            xyz   = XYZ(v[:xyz]...),
        )
    end
    vec
end

function get_data()
    path = @__DIR__() * "/snapshot-rev4.json"
    !isfile(path) && fetch_data(path)
    path |> read_data |> clean_data
end
