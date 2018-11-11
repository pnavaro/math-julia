
# $$
# \frac{d f}{dt} +  (v \frac{d f}{dx} - x \frac{d f}{dv}) = 0
# $$

# $$ 
# x \in [-\pi, \pi],\qquad y \in [-\pi, \pi] \qquad \mbox{ and } \qquad t \in [0, 200\pi] 
# $$

using  FFTW
using  LinearAlgebra
using  Plots, ProgressMeter
using  BenchmarkTools
pyplot()
#----------------------------------------------------------------------------

# ## Mesh parameters (matlab code)
# 
# ```m
# Nx=128;Ny=256;
# xmin=-pi; xmax=pi; 
# 
# dx=(xmax-xmin)/Nx; 
# x=xmin:dx:xmax-dx;
# 
# ymin=-pi; ymax=pi; 
# dy=(ymax-ymin)/Ny; 
# y=ymin:dy:ymax-dy;
# ```

# ## Julia type for mesh information
# 
# ```jl
# struct Mesh
#     nx   :: Int
#     ny   :: Int
#     xmin :: Float64
#     xmax :: Float64
#     ymin :: Float64
#     ymax :: Float64
#     dx   :: Float64
#     dy   :: Float64
#     x    :: Vector{Float64}
#     y    :: Vector{Float64}
# end
# 
# mesh = Mesh( 128, 256, -π, π, -π, π, 2π/128, 2π/256, ...)
# 
# ```
# 

struct Mesh
    
    nx   :: Int
    ny   :: Int
    xmin :: Float64
    xmax :: Float64
    ymin :: Float64
    ymax :: Float64
    dx   :: Float64
    dy   :: Float64
    x    :: Vector{Float64}
    y    :: Vector{Float64}
    
    function Mesh( xmin, xmax, nx, ymin, ymax, ny)
        dx, dy = (xmax-xmin)/nx, (ymax-ymin)/ny
        x = range(xmin, stop=xmax, length=nx+1)[1:end-1]  ## we remove the end point
        y = range(ymin, stop=ymax, length=ny+1)[1:end-1]  ## periodic boundary condition
        new( nx, ny, xmin, xmax, ymin, ymax, dx, dy, x, y)
    end
end

mesh = Mesh(-π, π, 128, -π, π, 256)

@show mesh.xmin, mesh.xmax, mesh.nx, mesh.dx
#----------------------------------------------------------------------------

# # Initialization of f : 2d array of double float
# 
# ```m
# f=zeros(Nx,Ny);
# for i=1:Nx
#     xx=xmin+(i-1)*dx;
#     for j=1:Ny
#         yy=ymin+(j-1)*dy;
#         f(i,j)=exp(-(xx-1)*(xx-1)/0.1)*exp(-(yy-1)*(yy-1)/0.1);
#     end
# end
# ```

# ```jl
# f = zeros(Float64,(mesh.nx,mesh.ny))
# 
# for (i, x) in enumerate(mesh.x), (j, y) in enumerate(mesh.y)
# 
#     f[i,j] = exp(-(x-1)*(x-1)/0.1)*exp(-(y-1)*(y-1)/0.1)
#         
# end
# ```

# ### Julia function to compute exact solution

function exact(tf, mesh)
   
    f = zeros(Float64,(mesh.nx, mesh.ny))
    for (i, x) in enumerate(mesh.x), (j, y) in enumerate(mesh.y)
        xn = cos(tf)*x - sin(tf)*y
        yn = sin(tf)*x + cos(tf)*y
        f[i,j] = exp(-(xn-1)*(xn-1)/0.1)*exp(-(yn-1)*(yn-1)/0.1)
    end

    f
end
#----------------------------------------------------------------------------

f = exact(0.0, mesh)
surface(f)
#----------------------------------------------------------------------------

# ## Create the gif to show what we are computing

function create_gif()
    x = y = range(-π, stop=π, length=40)
    n = 100
    
    prog = Progress(n,1) ## progress bar
    
    @gif for t in range(0, stop=2π, length=n)
        f(x,y) = exp(-((cos(t)*x-sin(t)*y)-1)^2/0.2)*exp(-((sin(t)*x+cos(t)*y)-1)^2/0.2)
        
        p = plot(x, y, f, st = [:surface])
    
        plot!(p[1])
        plot!(zlims=(-0.01,1.01))
    
        next!(prog) ## increment the progress bar
    end
end

create_gif();
#----------------------------------------------------------------------------

# ![](tmp.gif)

# ## Advection and loop over time
# ```m
# tf=200*pi;Nt=1000;dt=tf/Nt;
# kx=2*pi/(xmax-xmin)*[0:Nx/2-1,Nx/2-Nx:Nx-1-Nx];
# ky=2*pi/(ymax-ymin)*[0:Ny/2-1,Ny/2-Ny:Ny-1-Ny];
# 
# fnx=zeros(1,Nx);ffx=zeros(1,Nx);fny=zeros(1,Ny);ffy=zeros(1,Ny);
# 
# for n=1:Nt     
#     for i=1:Nx
#         xx=xmin+(i-1)*dx;
#         ffy=fft(f(i,:));
#         fny=real(ifft(exp(sqrt(-1)*xx*ky*tan(dt/2)).*ffy));
#         f(i,:)=fny;
#     end
#     
#     for j=1:Ny
#         yy=ymin+(j-1)*dy;
#         ffx=fft(f(:,j));
#         fnx=real(ifft(exp(-sqrt(-1)*yy*kx*sin(dt)).*transpose(ffx)));
#         f(:,j)=fnx;
#     end
# 
#     for i=1:Nx
#         xx=xmin+(i-1)*dx;
#         ffy=fft(f(i,:));
#         fny=real(ifft(exp(sqrt(-1)*xx*ky*tan(dt/2)).*ffy));
#         f(i,:)=fny;
#     end        
# end
# ```

# ## Function to compute error
# 
# ```m
# 
# % compute errors in Linfty norm
# error1=max(max(f-f_exact))
# 
# ```
# 
# - In julia the max value of an array is `maximum`.

function error1(f, f_exact)
    maximum(abs.(f .- f_exact))
end
#----------------------------------------------------------------------------

# ## Naive translation of the matlab code

function naive_from_matlab(tf, nt, mesh::Mesh)

    dt = tf/nt

    kx = 2π/(mesh.xmax-mesh.xmin)*[0:mesh.nx÷2-1;mesh.nx÷2-mesh.nx:-1]
    ky = 2π/(mesh.ymax-mesh.ymin)*[0:mesh.ny÷2-1;mesh.ny÷2-mesh.ny:-1]

    f = exact(0.0, mesh)

    for n=1:nt
       
       for (i, x) in enumerate(mesh.x)
           f[i,:]=real(ifft(exp.(1im*x*ky*tan(dt/2)).*fft(f[i,:])))
       end
       
       for (j, y) in enumerate(mesh.y)
           f[:,j]=real(ifft(exp.(-1im*y*kx*sin(dt)).*fft(f[:,j])))
       end
       
       for (i, x) in enumerate(mesh.x)
           f[i,:]=real(ifft(exp.(1im*x*ky*tan(dt/2)).*fft(f[i,:])))
       end
   end

    f
end
#----------------------------------------------------------------------------

nt, tf = 1000, 200
println( " error = ", error1(naive_from_matlab(tf, nt, mesh), exact(tf, mesh)))
@btime naive_from_matlab(tf, nt, mesh);
#----------------------------------------------------------------------------

# ###  Vectorized version
# 
# - We remove the for loops over direction x and y by creating the 2d arrays `exky` and `ekxy`.
# - We save cpu time by computing them before the loop over time

function vectorized(tf, nt, mesh::Mesh)

    dt = tf/nt

    kx = 2π/(mesh.xmax-mesh.xmin)*[0:mesh.nx÷2-1;mesh.nx÷2-mesh.nx:-1]
    ky = 2π/(mesh.ymax-mesh.ymin)*[0:mesh.ny÷2-1;mesh.ny÷2-mesh.ny:-1]

    f = exact(0.0, mesh)

    exky = exp.( 1im*tan(dt/2) .* mesh.x  .* ky')
    ekxy = exp.(-1im*sin(dt)   .* mesh.y' .* kx )
    
    for n = 1:nt
        f = real(ifft(exky .* fft(f, 2), 2))
        f = real(ifft(ekxy .* fft(f, 1), 1))
        f = real(ifft(exky .* fft(f, 2), 2))
    end

    f
end
#----------------------------------------------------------------------------

nt, tf = 1000, 200
println( " error = ", error1(vectorized(tf, nt, mesh), exact(tf, mesh)))
@btime vectorized(tf, nt, mesh);
#----------------------------------------------------------------------------

# ## Inplace computation 
# - We remove the Float64-Complex128 conversion by allocating the distribution function `f` as a Complex array
# - Note that we need to use the inplace assignement operator ".="  to initialize the `f` array.
# - We use inplace computation for fft with the "bang" operator `!`

function inplace(tf, nt, mesh::Mesh)

    dt = tf/nt

    kx = 2π/(mesh.xmax-mesh.xmin)*[0:mesh.nx÷2-1;mesh.nx÷2-mesh.nx:-1]
    ky = 2π/(mesh.ymax-mesh.ymin)*[0:mesh.ny÷2-1;mesh.ny÷2-mesh.ny:-1]
    
    f  = zeros(Complex{Float64},(mesh.nx,mesh.ny))
    f .= exact(0.0, mesh)

    exky = exp.( 1im*tan(dt/2) .* mesh.x  .* ky')
    ekxy = exp.(-1im*sin(dt)   .* mesh.y' .* kx )
    
    for n = 1:nt
        fft!(f, 2)
        f .= exky .* f
        ifft!(f,2)
        fft!(f, 1)
        f .= ekxy .* f
        ifft!(f, 1)
        fft!(f, 2)
        f .= exky .* f
        ifft!(f,2)        
    end

    real(f)
end
#----------------------------------------------------------------------------

nt, tf = 1000, 200
println( " error = ", error1(inplace(tf, nt, mesh), exact(tf, mesh)))
@btime inplace(tf, nt, mesh);
#----------------------------------------------------------------------------

# ### Use plans for fft

# - When you apply multiple fft on array with same shape and size, it is recommended to use fftw plan to improve computations.
# - Let's try to initialize our two fft along x and y with plans.

function with_fft_plans(tf, nt, mesh::Mesh)

    dt = tf/nt

    kx = 2π/(mesh.xmax-mesh.xmin)*[0:mesh.nx÷2-1;mesh.nx÷2-mesh.nx:-1]
    ky = 2π/(mesh.ymax-mesh.ymin)*[0:mesh.ny÷2-1;mesh.ny÷2-mesh.ny:-1]
    
    f  = zeros(Complex{Float64},(mesh.nx,mesh.ny))
    f .= exact(0.0, mesh)
    f̂  = similar(f)

    exky = exp.( 1im*tan(dt/2) .* mesh.x  .* ky')
    ekxy = exp.(-1im*sin(dt)   .* mesh.y' .* kx )
        
    Px = plan_fft(f, 1)
    Py = plan_fft(f, 2)
        
    for n = 1:nt
        
        f̂ .= Py * f
        f̂ .= f̂  .* exky
        f .= Py \ f̂
        
        f̂ .= Px * f
        f̂ .= f̂  .* ekxy 
        f .= Px \ f̂
        
        f̂ .= Py * f
        f̂ .= f̂  .* exky
        f .= Py \ f̂
        
    end

    real(f)
end
#----------------------------------------------------------------------------

nt, tf = 1000, 200
println( " error = ", error1(with_fft_plans(tf, nt, mesh), exact(tf, mesh)))
@btime with_fft_plans(tf, nt, mesh);
#----------------------------------------------------------------------------

# ## Inplace computation and fft plans
# 
# To apply fft plan to an array A, we use a preallocated output array Â by calling `mul!(Â, plan, A)`. 
# The input array A must be a complex floating-point array like the output Â.
# The inverse-transform is computed inplace by applying `inv(P)` with `ldiv!(A, P, Â)`.

function with_fft_plans_inplace(tf, nt, mesh::Mesh)

    dt = tf/nt

    kx = 2π/(mesh.xmax-mesh.xmin)*[0:mesh.nx÷2-1;mesh.nx÷2-mesh.nx:-1]
    ky = 2π/(mesh.ymax-mesh.ymin)*[0:mesh.ny÷2-1;mesh.ny÷2-mesh.ny:-1]
    
    f  = zeros(Complex{Float64},(mesh.nx,mesh.ny))
    f .= exact(0.0, mesh)
    f̂  = similar(f)

    exky = exp.( 1im*tan(dt/2) .* mesh.x  .* ky')
    ekxy = exp.(-1im*sin(dt)   .* mesh.y' .* kx )

    Px = plan_fft(f, 1)    
    Py = plan_fft(f, 2)
        
    for n = 1:nt
        
        mul!(f̂, Py, f)
        f̂ .= f̂ .* exky
        ldiv!(f, Py, f̂)
        
        mul!(f̂, Px, f)
        f̂ .= f̂ .* ekxy 
        ldiv!(f, Px, f̂)
        
        mul!(f̂, Py, f)
        f̂ .= f̂ .* exky
        ldiv!(f, Py, f̂)
        
    end

    real(f)
end
#----------------------------------------------------------------------------

nt, tf = 1000, 200
println( " error = ", error1(with_fft_plans_inplace(tf, nt, mesh), exact(tf, mesh)))
@btime with_fft_plans_inplace(tf, nt, mesh);
#----------------------------------------------------------------------------

# ## Explicit transpose of `f`
# 
# - Multidimensional arrays in Julia are stored in column-major order.
# - FFTs along y are slower than FFTs along x
# - We can speed-up the computation by allocating the transposed `f` 
# and transpose f for each advection along y.

function with_fft_transposed(tf, nt, mesh::Mesh)

    dt = tf/nt

    kx = 2π/(mesh.xmax-mesh.xmin)*[0:mesh.nx÷2-1;mesh.nx÷2-mesh.nx:-1]
    ky = 2π/(mesh.ymax-mesh.ymin)*[0:mesh.ny÷2-1;mesh.ny÷2-mesh.ny:-1]
    
    f  = zeros(Complex{Float64},(mesh.nx,mesh.ny))
    f̂  = similar(f)
    fᵗ = zeros(Complex{Float64},(mesh.ny,mesh.nx))
    f̂ᵗ = similar(fᵗ)

    exky = exp.( 1im*tan(dt/2) .* mesh.x' .* ky )
    ekxy = exp.(-1im*sin(dt)   .* mesh.y' .* kx )
    
    FFTW.set_num_threads(4)
    Px = plan_fft(f,  1, flags=FFTW.PATIENT)    
    Py = plan_fft(fᵗ, 1, flags=FFTW.PATIENT)
    
    f .= exact(0.0, mesh)
    
    for n = 1:nt
        transpose!(fᵗ,f)
        mul!(f̂ᵗ, Py, fᵗ)
        f̂ᵗ .= f̂ᵗ .* exky
        ldiv!(fᵗ, Py, f̂ᵗ)
        transpose!(f,fᵗ)
        
        mul!(f̂, Px, f)
        f̂ .= f̂ .* ekxy 
        ldiv!(f, Px, f̂)
        
        transpose!(fᵗ,f)
        mul!(f̂ᵗ, Py, fᵗ)
        f̂ᵗ .= f̂ᵗ .* exky
        ldiv!(fᵗ, Py, f̂ᵗ)
        transpose!(f,fᵗ)
    end
    real(f)
end
#----------------------------------------------------------------------------

nt, tf = 1000, 200
println( " error = ", error1(with_fft_transposed(tf, nt, mesh), exact(tf, mesh)))
@btime with_fft_transposed(tf, nt, mesh);
#----------------------------------------------------------------------------

tf, nt = 400π, 1000
mesh = Mesh(-π, π, 512, -π, π, 256)

inplace_bench = @benchmark inplace(tf, nt, mesh)
vectorized_bench = @benchmark vectorized(tf, nt, mesh)
with_fft_plans_bench = @benchmark with_fft_plans(tf, nt, mesh)
with_fft_plans_inplace_bench = @benchmark with_fft_plans_inplace(tf, nt, mesh)
with_fft_transposed_bench = @benchmark with_fft_transposed(tf, nt, mesh)
#----------------------------------------------------------------------------

d = Dict() 
d["vectorized"] = minimum(vectorized_bench.times) / 1e6
d["inplace"] = minimum(inplace_bench.times) / 1e6
d["with_fft_plans"] = minimum(with_fft_plans_bench.times) / 1e6
d["with_fft_plans_inplace"] = minimum(with_fft_plans_inplace_bench.times) / 1e6
d["with_fft_transposed"] = minimum(with_fft_transposed_bench.times) / 1e6;
#----------------------------------------------------------------------------

for (key, value) in sort(collect(d), by=last)
    println(rpad(key, 25, "."), lpad(round(value, digits=1), 6, "."))
end
#----------------------------------------------------------------------------

# ## Conclusion
# - Use pre-allocations of memory and inplace computation are very important
# - Try to always do computation on data contiguous in memory
# - In this notebook, use btime to not taking account of time consumed in 
# compilation.
