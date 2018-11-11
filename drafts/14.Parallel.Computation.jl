
# 
# Julia is not fully thread-safe yet.

# # Julia Tasks (aka Coroutines) 
# 
# ## Channels
# 
# Channels can be quite useful to pass data between running tasks, particularly those involving I/O operations.
# 
# 

@noinline function inner(x, y)
    s = zero(eltype(x))
    for i=eachindex(x)
        @inbounds s += x[i]*y[i]
    end
    return s
end

@noinline function innersimd(x, y)
    s = zero(eltype(x))
    @simd for i = eachindex(x)
        @inbounds s += x[i] * y[i]
    end
    return s
end

function timeit(n, reps)
    x = rand(Float32, n)
    y = rand(Float32, n)
    s = zero(Float64)
    time = @elapsed for j in 1:reps
        s += inner(x, y)
    end
    println("GFlop/sec        = ", 2n*reps / time*1E-9)
    time = @elapsed for j in 1:reps
        s += innersimd(x, y)
    end
    println("GFlop/sec (SIMD) = ", 2n*reps / time*1E-9)
end

timeit(1000, 1000)
#----------------------------------------------------------------------------

@noinline function element_wise_product(x, y)
    s = zeros(eltype(x),size(x))
    for i=eachindex(x)
        @inbounds s[i] = x[i]*y[i]^2-x[i]
    end
    return s
end

@noinline function element_wise_simd(x, y)
    s = zeros(eltype(x),size(x))
    @simd for i = eachindex(x)
        @inbounds s[i] = x[i] * y[i]^2-x[i]
    end
    return s
end

function timeit(n, reps)
    x = rand(Float32, n)
    y = rand(Float32, n)
    s = zeros(eltype(x),size(x))
    time = @elapsed for j in 1:reps
        s .+= element_wise_product(x, y)
    end
    println("GFlop/sec        = ", 2n*reps / time*1E-9)
    time = @elapsed for j in 1:reps
        s .+= element_wise_product(x, y)
    end
    println("GFlop/sec (SIMD) = ", 2n*reps / time*1E-9)
end

timeit(10000, 10000)
#----------------------------------------------------------------------------



function timeit(n, reps)
    x = rand(Float32, n)
    y = rand(Float32, n)
    s = zero(Float64)
    time = @elapsed for j in 1:reps
        s += inner(x, y)
    end
    println("GFlop/sec        = ", 2n*reps / time*1E-9)
    time = @elapsed for j in 1:reps
        s += innersimd(x, y)
    end
    println("GFlop/sec (SIMD) = ", 2n*reps / time*1E-9)
end

timeit(1000, 1000)
#----------------------------------------------------------------------------

function init!(u::Vector)
    n = length(u)
    dx = 1.0 / (n-1)
    @fastmath @inbounds @simd for i in 1:n ##by asserting that `u` is a `Vector` we can assume it has 1-based indexing
        u[i] = sin(2pi*dx*i)
    end
end

function deriv!(u::Vector, du)
    n = length(u)
    dx = 1.0 / (n-1)
    @fastmath @inbounds du[1] = (u[2] - u[1]) / dx
    @fastmath @inbounds @simd for i in 2:n-1
        du[i] = (u[i+1] - u[i-1]) / (2*dx)
    end
    @fastmath @inbounds du[n] = (u[n] - u[n-1]) / dx
end

function mynorm(u::Vector)
    n = length(u)
    T = eltype(u)
    s = zero(T)
    @fastmath @inbounds @simd for i in 1:n
        s += u[i]^2
    end
    @fastmath @inbounds return sqrt(s/n)
end

function main()
    n = 2000
    u = Vector{Float64}(undef, n)
    init!(u)
    du = similar(u)

    deriv!(u, du)
    nu = mynorm(du)

    @time for i in 1:10^6
        deriv!(u, du)
        nu = mynorm(du)
    end

    println(nu)
end

main()
#----------------------------------------------------------------------------

using Distributed
workers()
#----------------------------------------------------------------------------

addprocs(3)
#----------------------------------------------------------------------------

workers() ## proc 1 is now the master and is not a worker anymore
#----------------------------------------------------------------------------

psize = 8
@distributed for prank=1:psize
    println(myid()); ## return worker id
end;
#----------------------------------------------------------------------------

## Given Channels c1 and c2,
jobs = Channel(32) ## can hold a maximum of 32 objects of any type.
results = Channel(32)

## and a function `slow_double` which reads items from from c1, 
## doubles the item read, wait 1 second
## and writes a result to c2,
function slow_double()
    while true
        data = take!(jobs)
        sleep(1)
        put!(results, (myid(),data*2))    ## write out result
    end
end

function make_jobs(n)
    for i in 1:n
        put!(jobs, i)
    end
end

n = 8

@async make_jobs(n) ## feed the jobs channel with "n" jobs

## we can schedule `n` instances of `foo` to be active concurrently.
for _ in 1:n
    @async slow_double()
end

@elapsed while n > 0 ## print out results
    global n
    job_id, result = take!(results)
    println("$job_id finished data = $result")
    n = n - 1
end
#----------------------------------------------------------------------------

using Distributed, SharedArrays

@everywhere using Distributed, SharedArrays

@everywhere function do_work(x)
    sleep(1)
    return x^2
end

n = 8
S = SharedArray{Int,1}(n, init = S -> S[localindices(S)] = localindices(S))

@elapsed begin
    @distributed for i=1:n
        S[i] = do_work(S[i])
    end
end

@show S
#----------------------------------------------------------------------------

S
#----------------------------------------------------------------------------

@elapsed pmap(do_work, S)
#----------------------------------------------------------------------------

@show S
#----------------------------------------------------------------------------

@elapsed for i = 1:5
    println(do_work(i))
end
#----------------------------------------------------------------------------

workers()
#----------------------------------------------------------------------------

function timestep(b::Vector{T}, a::Vector{T}, Δt::T) where T
    @assert length(a)==length(b)
    n = length(b)
    b[1] = 1                            ## Boundary condition
    for i=2:n-1
        b[i] = a[i] + (a[i-1] - T(2)*a[i] + a[i+1]) * Δt
    end
    b[n] = 0                            ## Boundary condition
end

function heatflow(a::Vector{T}, nstep::Integer) where T
    b = similar(a)
    for t=1:div(nstep,2)                ## Assume nstep is even
        timestep(b,a,T(0.1))
        timestep(a,b,T(0.1))
    end
end

heatflow(zeros(Float32,10),2)           ## Force compilation
for trial=1:6
    a = zeros(Float32,1000)
    set_zero_subnormals(iseven(trial))  ## Odd trials use strict IEEE arithmetic
    @time heatflow(a,1000)
end
#----------------------------------------------------------------------------

3//4 + 2//7
#----------------------------------------------------------------------------

using LinearAlgebra
#----------------------------------------------------------------------------

A = [3//4+1im  2//5 1 //2 ; 3//4  2//7 1 //3; 4//5  2//7 1 //9]
#----------------------------------------------------------------------------

inv(A)
#----------------------------------------------------------------------------

det(A)
#----------------------------------------------------------------------------

A * inv(A)
#----------------------------------------------------------------------------


#----------------------------------------------------------------------------


#----------------------------------------------------------------------------
