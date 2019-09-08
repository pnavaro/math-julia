# Julia's Engineering and Design Tradoffs

- Type structures cannot bechanges after created (less dynamism but memory layout can be optimized for)
- All functions are JIT compiled via LLVM (interactive lags but massive runtime improvements)
- All functions specialize on types of arguments (more compilation but give generic programming structures)
- Julia is interactive (use it like Python and R, but makes it harder to get binaries)
- Julia has great methods for handling mutation (more optimization oppotunities like C/Fortran, but more cognative burden)
- Julia's Base library and most packages are written in Julia, (you can understand the source, but learn a new package)
- Julia has expensive tooling for code generation and metaprogramming (consise and more optimizations, but some codes can be for experienced users)

To me, this gives me a language with a lot of depth which works well for computationally-expensive scientific
applications.

[ChrisRackaukas slide](https://www.youtube.com/watch?v=zJ3R6vOhibA&feature=em-uploademail) 

---

# Type-Dispatch Programming

- Centered around implementing the generic template of the algorithm not around
building representations of data.
- The data type choose how to efficiently implement the algorithm.
- 

[JuliaCon 2019 | The Unreasonable Effectiveness of Multiple Dispatch | Stefan Karpinski](https://youtu.be/kc9HwsxE1OY)


# Example 

http://tutorials.juliadiffeq.org/html/type_handling/02-uncertainties.html

```julia
using DifferentialEquations, Measurements, Plots

g = 9.79 ± 0.02; # Gravitational constants
L = 1.00 ± 0.01; # Length of the pendulum

#Initial Conditions
u₀ = [0 ± 0, π / 60 ± 0.01] # Initial speed and initial angle
tspan = (0.0, 6.3)

#Define the problem
function simplependulum(du,u,p,t)
    θ  = u[1]
    dθ = u[2]
    du[1] = dθ
    du[2] = -(g/L)*θ
end

#Pass to solvers
prob = ODEProblem(simplependulum, u₀, tspan)
sol = solve(prob, Tsit5(), reltol = 1e-6)

# Analytic solution
u = u₀[2] .* cos.(sqrt(g / L) .* sol.t)

plot(sol.t, getindex.(sol.u, 2), label = "Numerical")
plot!(sol.t, u, label = "Analytic")
```

# Package

- `Project.toml`
- `Manifest.toml`
- `LOAD_PATH`


