# Installation
using Pkg

pkg" add CUDAdrv CUDAnative CuArrays"

using CUDAdrv, CUDAnative, CuArrays

CuArrays.version()

CuArrays.functionnal()

# Array programming

CuArray{Float32,2}(undef, 2, 2)

similar(a)

a = CuArray([1,2,3])

b = Array(a)

# API compatibilty with Base.Array

CuArrays.ones(2)

CuArrays.zeros(Float32, 2)

CuArrays.fill(42, (3,4))

rand(2, 2)

a = CuArray([1 2 3])

view(a, 2:2)

sum(a)

a * 2

a'

a * CuArray([1, 2, 3])

a = CuArray{Float32}(undef, (2,2))

## CURAND

rand!(a)

## CUBLAS

a * a

## CUSOLVER

LinearAlgebra.qr!(a)

## CUFFT

CUFFT.plan_fft(a) * a

## CUDDN

softmax(real(ans))

## CUSPARSE

sparse(a)

## Array programming

a = CuArray([1, 2 3])
b = CuArray([4, 5 6])

map(a) do x
    x + 1
end

a .+ 2b

reduce(+, a)

accumulate(+, b; dims=2)

findfirst(isequal(2), a)


using LinearAlgebra
using ForwardDiff

# squared error loss function
loss(w, b, x, y) = sum(abs2, y - (w*x .+ b)) / size(y, 2)
# get gradient w.r.t to `w`
loss∇w(w, b, x, y) = ForwardDiff.gradient(w -> loss(w, b, x, y), w)
# get derivative w.r.t to `b` (`ForwardDiff.derivative` is
# used instead of `ForwardDiff.gradient` because `b` is
# a scalar instead of an array)
lossdb(w, b, x, y) = ForwardDiff.derivative(b -> loss(w, b, x, y), b)

# proximal gradient descent function
function train(w, b, x, y; lr=0.1)
    w -= lmul!(lr, loss∇w(w, b, x, y))
    b -= lr * lossdb(w, b, x, y)
    return w, b
end

n, p = 100, 10
x = randn(n, p)'
y = sum(x[1:5,:]; dims=1) .+ randn(n)' * 0.1
w = 0.0001 * randn(1, p)
b = 0.0

for i = 1:50
   w, b = train(w, b, x, y)
   println(loss(w,b,x,y))
end


# Moving to GPU

x = CuArray(x)
y = CuArray(y)
w = CuArray(y)

# Custom Kernel
using BenchmarkTools

a = CuArrays.rand(Int, 1000)
using LinearAlgebra

norm(a)


@btime norm($a)


@btime norm($(Array(a)))

CuArrays.allowscalar(false)


a = CuARray(1:9_999_999)

a .+ reverse(a)

@time CuArrays.@sync a .+ reverse(a)

CuArrays.@time a .+ reverse(a)

@btime CuArrays.@sync $a .+ reverse($a)

@btime CuArrays.@sync $(Array(a)) .+ reverse($(Array(a)))


# NVIDIA Nsight Compute

$ nv-nsight-cu-cli --profile-from-start off julia

julia> CUDAdrv.@profile a .+ reverse(a)
julia> exit()

$ nsys launch julia

julia> CUDAdrv.@profile a .+ reverse(a)


# Interactive development

kernel() = (@cuprintln("foo"); return)

@cuda kernel()

kernel() = (@cuprintln("foo"); return)

@cuda kernel()


Significant overhead when you launch several kernels



a = CuArray(1:9_999_999)
c = similar(a)
c .= a .+ reverse(a)

function vadd_reverse(c, a, b)
    
    i = threadIdx().x
    if <= length(c)
        @inbounds c[i] = a[i] + reverse(b)[i]
    end
    return
end

@cuda threads = length(a) vadd_reverse(c, a, a)


# # Unsupported
# - Dynamic allocations
# - Garbage collection
# - Dynamic dispatch
# - Input/Output


function vadd_reverse(c, a, b)
    
    i = threadIdx().x
    if <= length(c)
        @inbounds c[i] = a[i] + b[end - i + 1]
    end
    return
end

@cuda threads = length(a) vadd_reverse(c, a, a)

attribute(device(), CUDAdrv.DEVICE_ATTRIBUTE_MAX_THREADS_PER_BLOCK)

function vadd_reverse(c, a, b)
    i = (blockIdx().x - 1) * blockDim().x + threadIdx().x
    if i <= length(c)
        @inbounds c[i] = a[i] + b[end - i + 1]
    end
    return
end

@btime CuArrays.@sync @cuda threads=1024 blocks=length($a)÷1024+1 vadd_reverse($c, $a, $a)

@btime CuArrays.@sync $a .+ reverse($a)


function configurator(kernel)
    config = launch_configuration(kernel.fun)
    threads = min(length(a), config.threads)
    blocks = cld(length(a), threads)
    return (threads=threads, blocks=blocks)
end

@cuda config=configurator vadd_reverse(c, a, a)

# Indexing
threadIdx().x; blockDim().y

# Cooperative groups
@cuda cooperative=true kernel(...)

# Shared memory
a = @cuStaticSharedMem(Int, 64)


# Dynamic parallelism

@cuda dynamic=true kernel(...)

# Standard output

@cuprintln("Thread $(threadIdx().x)")

# Atomics

@atomic a[...] += val

# Avoid thread divergence
# Reduce and coalesce global accesses
# Improve occupancy

# Early-free arrays  CuArrys.unsafe_free!
# Annotate with @inbounds
# Use 32 bits




