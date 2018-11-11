
# # Julia is fast

function matmul( A::Array{Float64,2}, B::Array{Float64,2})

    m, n  = size(A)
    p, q  = size(B)
    @assert n == p
    C = zeros(Float64,(m,q))
    for i = 1:m
        for j = 1:q
            C[i,j] = sum( A[i,:] .* B[:,j])
        end
    end
    C
end
#----------------------------------------------------------------------------

@show A = rand(Float64,(4,5))
@show B = rand(Float64,(5,4))
#----------------------------------------------------------------------------

matmul(A,B) == A * B
#----------------------------------------------------------------------------

A * B
#----------------------------------------------------------------------------

@code_llvm matmul(A,B)
#----------------------------------------------------------------------------


#----------------------------------------------------------------------------


#----------------------------------------------------------------------------

a = rand(10^7)
#----------------------------------------------------------------------------

sum(a)/length(a)
#----------------------------------------------------------------------------

using BenchmarkTools, Libdl
#----------------------------------------------------------------------------

C_code = """
##include <stddef.h>
double c_sum(size_t n, double *X) {
    double s = 0.0;
    for (size_t i = 0; i < n; ++i) {
        s += X[i];
    }
    return s;
}
"""

const Clib = tempname()   ## make a temporary file


## compile to a shared library by piping C_code to gcc
## (works only if you have gcc installed):

open(`gcc -fPIC -O3 -msse3 -xc -shared -o $(Clib * "." * Libdl.dlext) -`, "w") do f
    print(f, C_code) 
end

## define a Julia function that calls the C function:
c_sum(X::Array{Float64}) = ccall(("c_sum", Clib), Float64, (Csize_t, Ptr{Float64}), length(X), X)
#----------------------------------------------------------------------------

a = rand(10^7)
#----------------------------------------------------------------------------

c_sum(a)
#----------------------------------------------------------------------------

b = rand(10)
#----------------------------------------------------------------------------

run(`gfortran -fPIC -O3 -shared sumvec.F90 -o libsumvec.so`)
#----------------------------------------------------------------------------

function sumvec(x::Vector{Float64})
    outsum = Ref(0.0)
    N = Ref(length(x))
    ccall((:sumvec_, "./libsumvec.so"), Nothing,
        (Ptr{Float64}, Ref{Int64}, Ref{Float64}),
        x, N, outsum)
    return outsum[]
end
sumvec([1.0, 2.0])
#----------------------------------------------------------------------------

X = rand(10^7)
#----------------------------------------------------------------------------
