# -*- coding: utf-8 -*-

function buildsparsematrix(n, dt, h)

    nsq = n * n

    d1 = zeros(nsq)
    d2 = zeros(nsq)
    d3 = zeros(nsq)
    d4 = zeros(nsq)
    d5 = zeros(nsq)

    csound = 1.0
    cfl = csound * dt / h
    csq = csound * csound 
    ta  =   1.0 / dt^2 + 2csq / h^2 # diagonal term
    tb  = - 0.5 * csq / h^2

    for k = 1:nsq

       if( k == 1 )  # bottom left
          d1[k] =  0.0
          d2[k] =  0.0
          d3[k] =  1.0	
          d4[k] = -0.5
          d5[k] = -0.5
       elseif( k > 1 && k < n ) # left side
          d1[k] = 0.0
          d2[k] = 0.0
          d3[k] = 1.0	
          d4[k] = 0.0
          d5[k] = 0.0
       elseif( k == n ) # top left
          d1[k] =  0.0
          d2[k] = -0.5
          d3[k] =  1.0	
          d4[k] =  0.0
          d5[k] = -0.5
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
             d1[k] = tb
             d2[k] = tb
             d3[k] = ta		# interior
             d4[k] = tb
             d5[k] = tb
          end
       elseif ( k == (n-1)*n+1 ) 
          d1[k] = -.5
          d2[k] = 0.0
          d3[k] = 1.0		# bottom right
          d4[k] = -.5
          d5[k] = 0.0
       elseif ( k > nsq-n+1 && k < nsq ) 
          d1[k] = 0.0
          d2[k] = 0.0
          d3[k] = 1.0 		# right side
          d4[k] = 0.0
          d5[k] = 0.0
       elseif ( k == nsq) 
          d1[k] = -.5
          d2[k] = -.5
          d3[k] = 1.0		# top right
          d4[k] = 0.0
          d5[k] = 0.0
       end

    end

end


function asub( x, v )

    n = size(v)[1]
    nsq = n * n

    for k = 1:nsq

        v[k] = 0.0

        if( k == 1 ) then

            v[k] = d3[k] * x[k] + d4[k] * x[k+1] + d5[k] * x[k+n]

        elseif( k > 1 && k <= n ) 

            v[k] =  d2[k] * x[k-1] + d3[k] * x[k] + d4[k] * x[k+1] + d5[k] * x[k+n]

	    elseif( k > n && k < (n-1)*n ) 

            v[k] = d1[k] * x[k-n] + d2[k] * x[k-1] + d3[k] * x[k] + d4[k] * x[k+1] + d5[k] * x[k+n]

	    elseif( k >= (n-1)*n && k <= n*n-1 )

            v[k] = d1[k] * x[k-n] + d2[k] * x(k-1) + d3[k] * x[k] + d4[k] * x[k+1]

	    elseif( k == n*n )

            v[k] = d1[k] * x[k-n] + d2[k] * x[k-1] + d3[k] * x[k]

        end

    end

end

function atsub( x, v )

    n = size(v)[1]
    nsq = n * n

    for k in eachindex(v)

       v[k] = 0.0

       if( k == 1 ) then

          v[k] = d3[k]*x[k]+d2[k+1]*x[k+1]+d1[k+n]*x[k+n]

       elseif( k > 1 && k <= n ) then

          v[k] =  d4[k-1]*x[k-1] + d3[k]*x[k] + d2[k+1]*x[k+1] + d1[k+n]*x[k+n]

       elseif( k > n && k < n*(n-1) ) then

          v[k] = d5[k-n]*x[k-n]+d4[k-1]*x[k-1] + d3[k]*x[k]+d2[k+1]*x[k+1]+d1[k+n]*x[k+n]

       elseif( k >= n*(n-1) && k <= nsq-1 ) then

           v[k] = d5[k-n]*x[k-n]+d4[k-1]*x[k-1] + d3[k]*x[k]+d2[k+1]*x[k+1]

       elseif( k == nsq ) then

           v[k] = d5[k-n]*x[k-n]+d4[k-1]*x[k-1]+d3[k]*x[k]

       end

    end

end

# +
"""
    sparsecg( b, n, x)


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

    eps2 = n*eps^2        # Criterion for sum-squared residuals
    irst = 0                # Number of restarts attempted internally

    @label restart 
    irst = irst+1
    asub(x,xi)        #evaluate the starting gradient,
    rp   = 0
    bsq  = 0

    for j = 1:n
        bsq=bsq+b[j]^2    #and the magnitude of the right side
        xi[j]=xi[j]-b[j]
        rp=rp+xi[j]^2    
    end

    atsub( xi, g)
    for j=1:n
        g[j]=-g[j]
        h[j]=g[j]
    end 

    for iter = 1:10n    #Main iteration loop.
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
        atsub( xj, xi )    #Compute gradient for next iteration
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

function lighthill( n )

      nsq = n * n

      b = zeros(nsq) 
      c = zeros(nsq)
      x = zeros(nsq)

      phi0 = zeros(n,n)
      phi1 = zeros(n,n)
      phi2 = zeros(n,n)

      steps = 1000
      dt = 0.2

      csound = 10
      h      = 10
      tau    = 30
      omega  = 2pi / tau

      it     = 1

      buildsparsematrix(n, dt, h)

      csq   = csound * csound
      dh    = h + h
      hsq   = h * h
      xc    = 0.5 * h * n
      yc    = 0.5 * h * n

      time = 0.0

      for i = 1:n, j = 1:n
         k = ( i-1 ) * n + j 
         c[k] = 0
      end

      for istep = 1:steps

         i = n ÷ 2- 10
         j = n ÷ 2
         k = ( i-1 ) * n + j 
         c[k] = sin(omega*time+1e-5)
         i = n ÷ 2+ 10
         j = n ÷ 2
         k = ( i-1 ) * n + j 
         c[k] = sin(omega*time+1e-5)

         for i = 2:n-1

           j = 1  # bottom

           ic = ( i-1) * n + j

           phix = (phi2[i+1,j]-phi2[i-1,j])/dh
           phiy = (-3*phi2[i,j]+4*phi2[i,j+1]-phi2[i,j+2])/dh
	       xm   = i * h - xc
	       ym   = j * h - yc
	       rm   = sqrt(xm*xm + ym*ym)
	       dphi = xm/rm * phix + ym/rm * phiy
           b[ic] = phi2[i,j] - csound * dt * dphi

           j = n          # top

           phix = (phi2[i+1,j]-phi2[i-1,j])/dh
           phiy = (3*phi2[i,j]-4*phi2[i,j-1]+phi2[i,j-2])/dh
	       xm   = i * h - xc
	       ym   = j * h - yc
	       rm   = sqrt(xm*xm + ym*ym)
	       dphi = xm/rm * phix + ym/rm * phiy
           b[ ic+n-1 ] = phi2[i,j] - csound * dt * dphi

        end
  
        for j = 2:n-1

           i = 1          # left side

           phix = (-3*phi2[i,j]+4*phi2[i+1,j]-phi2[i+2,j])/dh
           phiy = (phi2[i,j+1]-phi2[i,j-1])/dh
	       xm   = i * h - xc
	       ym   = j * h - yc
	       rm   = sqrt(xm*xm + ym*ym)
	       dphi = xm/rm * phix + ym/rm * phiy
           b[j]  = phi2[i,j] - csound * dt * dphi

           i = n          # right side

           phix = (3*phi2[i,j]-4*phi2[i-1,j]+phi2[i-2,j])/dh
           phiy = (phi2[i,j+1]-phi2[i,j-1])/dh
	       xm   = i * h - xc
	       ym   = j * h - yc
	       rm   = sqrt(xm*xm + ym*ym)
	       dphi = xm/rm * phix + ym/rm * phiy
           b[nsq-n+j] = phi2[i,j] - csound * dt * dphi

        end
  
        b[ 1       ] = 0.0	
        b[ n       ] = 0.0
        b[ nsq     ] = 0.0
        b[ nsq-n+1 ] = 0.0

        ta =   1.0 / dt^2 + 2.0 * csq / hsq

        for i = 2:n-1, j = 2:n-1

            k = ( i-1) * n + j
	        b[k] = 2.0 * phi2[i,j] / dt^2 - ta * phi1[i, j] + 0.5 * csq * ( phi1[i+1,j] + phi1[i-1,j] + phi1[i,j-1] + phi1[i,j+1] ) / hsq  + c[k]
        end

        rsq = sparsecg( b, nsq, x )

	    phi0 .= phi1
	    phi1 .= phi2

        for i = 1:n, j = 1:n
            k = (i-1) * n + j
	        phi2[ i, j] = x[k]
        end

        time = time + dt
        cfl  = dt * csound / h

      end # next time step

end

lighthill(100)
