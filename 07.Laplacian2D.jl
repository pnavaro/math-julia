# -*- coding: utf-8 -*-
using Plots
using LinearAlgebra

# +
struct Laplacian

    n :: Int
    d1 :: Vector{Float64}
    d2 :: Vector{Float64}
    d3 :: Vector{Float64}
    d4 :: Vector{Float64}
    d5 :: Vector{Float64}

end

# +
function buildsparsematrix(n)

    nsq = n * n

    d1 = zeros(nsq)
    d2 = zeros(nsq)
    d3 = zeros(nsq)
    d4 = zeros(nsq)
    d5 = zeros(nsq)

    for k = 1:nsq

       if( k == 1 )  # bottom left
          d3[k] =  1	
       elseif( k > 1 && k < n ) # left side
          d3[k] = 1	
       elseif( k == n ) # top left
          d3[k] =  1
       elseif( k > n && k <= (n-1)*n ) 
          if( mod( k, n ) == 0 ) 
             d1[k] =  0.0
             d2[k] =  0.0
             d3[k] =  1.0		# top
             d4[k] =  0.0
             d5[k] =  0.0
          elseif( mod( k-1, n ) == 0 ) 
             d1[k] =  0.0
             d2[k] =  0.0
             d3[k] =  1.0		# bottom
             d4[k] =  0.0
             d5[k] =  0.0
          else
             d1[k] = -1
             d2[k] = -1
             d3[k] =  4		# interior
             d4[k] = -1
             d5[k] = -1
          end
       elseif ( k == (n-1)*n+1 ) 
          d3[k] = 1		# bottom right
       elseif ( k > nsq-n+1 && k < nsq ) 
          d3[k] = 1 		# right side
       elseif ( k == nsq) 
          d3[k] = 1		# top right
       end

    end

    Laplacian(n, d1, d2, d3, d4, d5)

end


# +
function asub!( v, L, x )

    n = L.n
    nsq = n * n

    for k in eachindex(v) 

        v[k] = 0.0

    end

    k = 1
    v[k] = L.d3[k] * x[k] + L.d4[k] * x[k+1] + L.d5[k] * x[k+n]

    for k = 2:n 
        v[k] =  L.d2[k] * x[k-1] + L.d3[k] * x[k] + L.d4[k] * x[k+1] + L.d5[k] * x[k+n]
    end

	for k = n+1:(n-1)*n-1
        v[k] = L.d1[k] * x[k-n] + L.d2[k] * x[k-1] + L.d3[k] * x[k] + L.d4[k] * x[k+1] + L.d5[k] * x[k+n]
    end

	for k = (n-1)*n:n*n-1
        v[k] = L.d1[k] * x[k-n] + L.d2[k] * x[k-1] + L.d3[k] * x[k] + L.d4[k] * x[k+1]
    end

	k = n*n
    v[k] = L.d1[k] * x[k-n] + L.d2[k] * x[k-1] + L.d3[k] * x[k]

end

# +
function atsub!( v, L, x )

    n = L.n
    nsq = n * n

    for k in eachindex(v)
       v[k] = 0.0
    end

    k = 1
    v[k] = L.d3[k]*x[k]+L.d2[k+1]*x[k+1]+L.d1[k+n]*x[k+n]

    for k=2:n
        v[k] =  L.d4[k-1]*x[k-1] + L.d3[k]*x[k] + L.d2[k+1]*x[k+1] + L.d1[k+n]*x[k+n]
    end

    for k = n+1:n*(n-1)-1
        v[k] = L.d5[k-n]*x[k-n]+L.d4[k-1]*x[k-1] + L.d3[k]*x[k]+L.d2[k+1]*x[k+1]+L.d1[k+n]*x[k+n]
    end

    for k = n*(n-1):nsq-1
        v[k] = L.d5[k-n]*x[k-n]+L.d4[k-1]*x[k-1] + L.d3[k]*x[k]+L.d2[k+1]*x[k+1]
    end

    k = nsq
    v[k] = L.d5[k-n]*x[k-n]+L.d4[k-1]*x[k-1]+L.d3[k]*x[k]

end

# +
"""
    sparsecg!( x, L, b)


Solves the linear system L.x=b for the vector X of length n, 
given the right hand vector B, and given two functions, 
`asub!(xout, L, xin)` and `atsub!(xout, L, xin)`, which respectively 
calculate `L . x` and `Lᵗ.x` for x given as their first arguments, 
returning the result in their second arguments. 

These functions should take every advantage of the 
sparseness of the second matrix L. On input, `x` should be set to a 
first guess of the desire solution (all zero components is fine). 
On output, `x` the solution vector, and `rsq` is the sum of the squares of 
the components of the residual vector `L.x-b`. If this is not small, then 
the matrix is numerically singular and the solution represents a least 
squares best approximation.

"""
function sparsecg!( x, L, b)

    eps = 1.e-7
    # Maximum anticipated N, and r.m.s accuracy desired

    n = L.n * L.n
    g = zeros(n)
    h = zeros(n)
    xi = zeros(n)
    xj = zeros(n)

    eps2 = n*eps^2        # Criterion for sum-squared residuals
    irst = 0                # Number of restarts attempted internally

    @label restart 
    irst = irst+1
    asub!(xi, L, x)        #evaluate the starting gradient,
    rp   = 0
    bsq  = 0

    for j = 1:n
        bsq=bsq+b[j]^2    #and the magnitude of the right side
        xi[j]=xi[j]-b[j]
        rp=rp+xi[j]^2    
    end

    atsub!( g, L, xi)
    for j=1:n
        g[j]=-g[j]
        h[j]=g[j]
    end 

    for iter = 1:10n    #Main iteration loop.
        asub!( xi, L, h )
        anum = 0.
        aden = 0.
        for j=1:n
            anum = anum + g[j]*h[j]
            aden = aden + xi[j]^2
        end

        ( aden == 0 ) && @error "very singular matrix'"

        anum = anum / aden
        for j = 1:n
            xi[j]=x[j]
            x[j] =x[j]+anum*h[j]
        end

        asub!( xj, L, x )
        rsq = 0.

        for j = 1:n
            xj[j]=xj[j] - b[j]
            rsq = rsq+xj[j]^2
        end

        ( rsq == rp && rsq <= bsq*eps2) && return rsq #converged normal return.

        if(rsq > rp)     #Not improving. do a restart.

            for j=1:n
                x[j]=xi[j]
            end

            ( irst >= 3 ) && return     rsq

            # This is a normal return    when we run into roundoff 
            # error before satisfaying the return above
            @goto restart

        end

        rp = rsq
        atsub!( xi, L, xj )    #Compute gradient for next iteration
        gg = 0
        dgg = 0.
        for j = 1:n
           gg = gg+ g[j]^2
           dgg = dgg + ( xi[j] + g[j])*xi[j]
        end

        ( gg == 0. )  && return rsq  # A rare but normal return

        gam = dgg / gg
        for j = 1:n
            g[j] = -xi[j]
            h[j] = g[j] + gam * h[j]
        end
    end 

    @error "Too many iterations"

end

# +
n = 100
nsq = n * n

b = zeros(nsq) 
x = zeros(nsq)

phi = zeros(n,n)
rho = zeros(n,n)

xgrid = LinRange( -pi, pi, n)
ygrid = LinRange( -pi, pi, n)

h = 2π / (n-1)

L = buildsparsematrix(n)

rho .= 2 .* sin.(xgrid) .* sin.(ygrid)'

for i = 2:n-1, j = 2:n-1

    k = ( i-1) * n + j
    b[k] = rho[i,j]  * h^2

end

@show rsq = sparsecg!( x, L, b )

for i = 1:n, j = 1:n
    k = (i-1) * n + j
    phi[ i, j] = x[k]
end

println( norm( phi .- sin.(xgrid) .* sin.(ygrid)'))

surface(phi)
# -

using DifferentialEquations

CenteredDifference{2}(2, 2, h, 100)


