Base.@kwdef struct Line{N<:Number}
    slope::N
    intercept::N
end

_distance_from_origin(l::Line) = abs(l.intercept) / sqrt((l.slope ^ 2) + 1)

_length_of_ray_until_intersect(θ, l::Line) = l.intercept / (sin(θ) - l.slope * cos(θ))

