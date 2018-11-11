
# *An intro to high performance custom arrays by Matt Bauman*
# 
# https://youtu.be/jS9eouMJf_Y

using BenchmarkTools
#----------------------------------------------------------------------------

A = rand(1000,1000)
#----------------------------------------------------------------------------

function weighted_sum( A, weights=ones(size(A)))
    r = zero(A[1])
    for i in eachindex(A, weights)
        r += A[i]*weights[i]
    end
    return r
end
@btime weighted_sum(A)
#----------------------------------------------------------------------------

@btime sum(A)
#----------------------------------------------------------------------------

module V1
struct OnesMatrix <: AbstractArray{Int, 2}
    m::Int
    n::Int
end
Base.size(o::OnesMatrix) = (o.m, o.n)
Base.getindex(o::OnesMatrix, i::Int, j::Int) = 1
end 
#----------------------------------------------------------------------------

x = V1.OnesMatrix(1000,1000)
#----------------------------------------------------------------------------

function weighted_sum( A, weights=V1.OnesMatrix(size(A)...))
    r = zero(A[1])
    for i in eachindex(A, weights)
        r += A[i]*weights[i]
    end
    return r
end
@btime weighted_sum(A)
#----------------------------------------------------------------------------

# Add bounds checking

module V2
struct OnesMatrix <: AbstractArray{Int, 2}
    m::Int
    n::Int
end
Base.size(o::OnesMatrix) = (o.m, o.n)
function Base.getindex(o::OnesMatrix, i::Int, j::Int)
    checkbounds(o, i, j)
    1
end
end 
#----------------------------------------------------------------------------

function weighted_sum( A, weights=V2.OnesMatrix(size(A)...))
    r = zero(A[1])
    @inbounds for i in eachindex(A, weights)
        r += A[i]*weights[i]
    end
    return r
end
@btime weighted_sum($A)
#----------------------------------------------------------------------------

module V3
struct OnesMatrix <: AbstractArray{Int, 2}
    m::Int
    n::Int
end
Base.size(o::OnesMatrix) = (o.m, o.n)
@inline function Base.getindex(o::OnesMatrix, i::Int, j::Int)
    @boundscheck begin
        checkbounds(o, i, j)
    end
    1
end
end 
#----------------------------------------------------------------------------

function weighted_sum( A, weights=V3.OnesMatrix(size(A)...))
    r = zero(A[1])
    @inbounds for i in eachindex(A, weights)
        r += A[i]*weights[i]
    end
    return r
end
@btime weighted_sum(A)
#----------------------------------------------------------------------------

module V4
struct OnesMatrix <: AbstractArray{Int, 2}
    m::Int
    n::Int
end
Base.size(o::OnesMatrix) = (o.m, o.n)
Base.IndexStyle(::Type{OnesMatrix}) = IndexLinear()
@inline function Base.getindex(o::OnesMatrix, i::Int)
    @boundscheck begin
        checkbounds(o, i)
    end
    1
end
end 
#----------------------------------------------------------------------------

function weighted_sum( A, weights=V4.OnesMatrix(size(A)...))
    r = zero(A[1])
    for i in eachindex(A, weights)
        r += A[i]*weights[i]
    end
    return r
end
@btime weighted_sum(A)
#----------------------------------------------------------------------------
