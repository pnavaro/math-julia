# -*- coding: utf-8 -*-
# +
"""
    sparsecg( b, n, x, rsq)


Solves the linear system A.x=b for the vector X of length n, 
given the right hand vector B, and given two functions, 
`asub(xin, xout)` and `atsub(xin,xout)`, which respectively 
calculate `A . x` and `Aᵗ.x` for x given as their first arguments, 
returning the result in their second arguments. 

These functions should take every advantage of the 
sparseness of the second matrix A. On input, X should be set to a 
first guess of the desire solution (all zero components is fine). 
On output, X the solution vector, and `rsq` is the sum of the squares of 
the components of the residual vector `A.x-b`. If this is not small, then 
the matrix is numerically singular and the solution represents a least 
squares best approximation.

"""
function sparsecg( b, n, x)

    eps = 1.e-7
    # Maximum anticipated N, and r.m.s accuracy desired

    g = zeros(n)
    h = zeros(n)
    xi = zeros(n)
    xj = zeros(n)

    eps2 = n*eps^2		# Criterion for sum-squared residuals
    irst = 0			    # Number of restarts attempted internally

    @label restart 
    irst = irst+1
    asub(x,xi)		#evaluate the starting gradient,
    rp   = 0
    bsq  = 0

    for j = 1:n
        bsq=bsq+b[j]^2	#and the magnitude of the right side
        xi[j]=xi[j]-b[j]
        rp=rp+xi[j]^2	
    end

    atsub( xi, g)
    for j=1:n
        g[j]=-g[j]
        h[j]=g[j]
    end 

    for iter = 1:10n	#Main iteration loop.
	    asub( h, xi )
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

        asub( x, xj )
	    rsq = 0.

	    for j = 1:n
	        xj[j]=xj[j] - b[j]
	        rsq = rsq+xj[j]^2
        end

	    ( rsq == rp && rsq <= bsq*eps2) && return rsq #converged normal return.

        if(rsq > rp) 	#Not improving. do a restart.

	        for j=1:n
	            x[j]=xi[j]
            end

            ( irst >= 3 ) && return	 rsq

            # This is a normal return	when we run into roundoff 
            # error before satisfaying the return above
            @goto restart

        end

	    rp = rsq
	    atsub( xj, xi )	#Compute gradient for next iteration
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
# -

using Random
rng = MersenneTwister(1)
n = 5
A = rand(rng, n, n)
b = collect(1:n)
A

A \ b

function asub( xin, xout)
    xout .= A * xin
end
function atsub( xin, xout)
    xout .= A'xin
end

x = zeros(n)
sparsecg(b, n, x)

x


