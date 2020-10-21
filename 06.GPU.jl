# -*- coding: utf-8 -*-
# ---
# jupyter:
#   jupytext:
#     cell_metadata_filter: -all
#     formats: jl:light,ipynb
#     text_representation:
#       extension: .jl
#       format_name: light
#       format_version: '1.5'
#       jupytext_version: 1.6.0
#   kernelspec:
#     display_name: Julia 1.5.2
#     language: julia
#     name: julia-1.5
# ---

# # Installation

import Pkg; Pkg.activate(@__DIR__); Pkg.instantiate()

using Plots

using BenchmarkTools
using CUDA
using Random
using Test
using LinearAlgebra
using ForwardDiff
using ProgressMeter

CUDA.version()

# Useful function to enable GPU version of your code

CUDA.functional()

for device in CUDA.devices()
    @show capability(device)
    @show name(device)
end

# ## Array programming

# ### Construction

a = CuArray{Float32,2}(undef, 2, 2)

similar(a)

a = CuArray([1,2,3])

# ## Transfer to CPU
#
# b is allocated on the CPU, a data transfer is made

b = Array(a)

# ### API compatibilty with Base.Array

CUDA.ones(2)

a = CUDA.zeros(Float32, 2)

a isa AbstractArray

CUDA.fill(42, (3,4))

# ## Random numbers

CUDA.rand(2, 2)

CUDA.randn(2, 1)

x = CUDA.CuArray(0:0.01:1.0)
nt = length(x)
y = 0.2 .+ 0.5 .* x + 0.1 .* CUDA.randn(nt);
scatter( Array(x), Array(y))
plot!( x -> 0.2 + 0.5x)
xlims!(0,1)
ylims!(0,1)

X = hcat(CUDA.ones(nt), x)

@show β = pinv(X)  * y

a = CuArray([1 2 3])

view(a, 2:3)

sum(a)

a * 2

a'

a * CuArray([1, 2, 3])

a = CuArray{Float32}(undef, (2,2))

# +
a = CuArray([1 2 3])
b = CuArray([4 5 6])

map(a) do x
    x + 1
end

a .+ 2b

reduce(+, a)

accumulate(+, b; dims=2)

findfirst(isequal(2), a)
# -


# # CURAND

CUDA.rand!(a)

# # CUBLAS

a * a

# # CUSOLVER

using LinearAlgebra
LinearAlgebra.qr!(a)

L, ipiv = CUDA.CUSOLVER.getrf!(a)
CUDA.CUSOLVER.getrs!('N', L, ipiv, CUDA.ones(2))

# # CUFFT

fft = CUFFT.plan_fft(a) 
fft * a

ifft = CUFFT.plan_ifft(a)
real(ifft * (fft * a))

# # CUDDN

CUDA.CUDNN.softmax(real(ans))

# # CUSPARSE

CUDA.CUSPARSE.CuSparseMatrixCSR(a)

# ## Workflow
#
# A typical approach for porting or developing an application for the GPU is as follows:
#
# 1. develop an application using generic array functionality, and test it on the CPU with the Array type
# 2. port your application to the GPU by switching to the CuArray type
# 3. disallow the CPU fallback ("scalar indexing") to find operations that are not implemented for or incompatible with GPU execution
# 4. (optional) use lower-level, CUDA-specific interfaces to implement missing functionality or optimize performance

# ## Linear regression example

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

err = Float64[]
@showprogress 1 for i = 1:50
   w, b = train(w, b, x, y)
   push!(err, loss(w,b,x,y))
end


plot(err)


# ### Moving to GPU

# +
n, p = 100, 10
x = randn(n, p)'
y = sum(x[1:5,:]; dims=1) .+ randn(n)' * 0.1
w = 0.0001 * randn(1, p)
b = 0.0
x = CuArray(x)
y = CuArray(y)
w = CuArray(w)

err = Float64[]
@showprogress 1 for i = 1:50
   w, b = train(w, b, x, y)
   push!(err, loss(w,b,x,y))
end
# -

plot(err)

# # Custom Kernel

# - you cannot allocate memory, 
# - I/O is disallowed, 
# - badly-typed code will not compile. 
#
# Keep kernels simple, and only incrementally port code while continuously verifying that it still compiles and executes as expected.

# +
a = CUDA.zeros(1024)

function kernel(a)
    i = threadIdx().x
    a[i] += 1
    return
end

@cuda threads=length(a) kernel(a)
# -

a = CUDA.rand(Int, 1000)

norm(a)


@btime norm($a)


@btime norm($(Array(a)))

# The `norm` computation is much faster on the CPU

CUDA.allowscalar(false)


a = CuArray(1:9_999_999);

a .+ reverse(a);

# You need two kernels to perfom this last computation. @time is not the right tool to evaluate the elasped time. The task is scheduled on the GPU device but not executed. It will be executed when you will fetch the result on the CPU.

@time CUDA.@sync a .+ reverse(a);

CUDA.@time a .+ reverse(a);

@btime CUDA.@sync $a .+ reverse($a);

@btime CUDA.@sync $(Array(a)) .+ reverse($(Array(a)));


# # NVIDIA Nsight Compute
#
# ```bash
# $ nv-nsight-cu-cli --profile-from-start off julia
# ```
# ```julia-repl
# julia> CUDAdrv.@profile a .+ reverse(a)
# julia> exit()
# ```
#
# ```bash
# $ nsys launch julia
# ```
# ```julia-repl
# julia> CUDAdrv.@profile a .+ reverse(a)
# ```


# # Interactive development

kernel() = (@cuprintln("foo"); return)

@cuda kernel()

kernel() = (@cuprintln("foo"); return)

@cuda kernel()


# There is a significant overhead when you launch several kernels

a = CuArray(1:9_999_999)
c = similar(a)
c .= a .+ reverse(a);

function vadd_reverse(c, a, b)
    i = threadIdx().x
    if i <= length(c)
        @inbounds c[i] = a[i] + reverse(b)[i]
    end
    return
end

# # Unsupported
#
# ```julia
# @cuda threads = length(a) vadd_reverse(c, a, a)
# ```
# will raise an error because some features are not supported on the GPU
#
# - Dynamic allocations
# - Garbage collection
# - Dynamic dispatch
# - Input/Output


function vadd_reverse(c, a, b)
    
    i = threadIdx().x
    if i <= length(c)
        @inbounds c[i] = a[i] + b[end - i + 1]
    end
    return
end

# The following expression will also raise an error because you can't loop over an array
# on GPU in the same way.
# ```julia
# @cuda threads = length(a) vadd_reverse(c, a, a)
# ```

attribute(device(), CUDA.DEVICE_ATTRIBUTE_MAX_THREADS_PER_BLOCK)

function vadd_reverse(c, a, b)
    i = (blockIdx().x - 1) * blockDim().x + threadIdx().x
    if i <= length(c)
        @inbounds c[i] = a[i] + b[end - i + 1]
    end
    return
end

# The kernel you built is twice faster 

@btime CUDA.@sync @cuda threads=1024 blocks=length($a)÷1024+1 vadd_reverse($c, $a, $a)

@btime CUDA.@sync $a .+ reverse($a);


# To adapt the code to your device, use this configurator function

function configurator(kernel)
    config = launch_configuration(kernel.fun)
    threads = min(length(a), config.threads)
    blocks = cld(length(a), threads)
    return (threads=threads, blocks=blocks)
end

@cuda config=configurator vadd_reverse(c, a, a)

# # Indexing

# # Cooperative groups
#
# https://devblogs.nvidia.com/cooperative-groups/
#
# ```julia
# @cuda cooperative=true kernel(...)
# ```
#
# # Shared memory
#
# https://devblogs.nvidia.com/using-shared-memory-cuda-cc/
#
# ```julia
# a = @cuStaticSharedMem(Int, 64)
# ```


# # Dynamic parallelism
#
# https://devblogs.nvidia.com/cuda-dynamic-parallelism-api-principles/
#
# @cuda dynamic=true kernel(...)

# # Standard output
#
# ```julia
# @cuprintln("Thread $(threadIdx().x)")
# ```

# # Atomics
#
# ```julia
# @atomic a[...] += val
# ```

# ## GPU programming performance tips
#
# - Avoid thread divergence (https://cvw.cac.cornell.edu/gpu/thread_div)
# - Reduce and coalesce global accesses
# - Improve occupancy
# - Early-free arrays  `CuArrays.unsafe_free!` (https://juliagpu.gitlab.io/CUDA.jl/usage/memory/)
# - Annotate with `@inbounds`
# - Use 32 bits for float and integers


