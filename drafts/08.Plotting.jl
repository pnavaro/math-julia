
# # Plotting

using Plots
#----------------------------------------------------------------------------

x = -3:0.1:3
square(x) = x^2

y = square.(x)
#----------------------------------------------------------------------------

gr()
#----------------------------------------------------------------------------

plot(x, y, label="line")
scatter!(x, y, label="points")
#----------------------------------------------------------------------------

plotlyjs()
#----------------------------------------------------------------------------

plot(x, y, label="line")
scatter!(x, y, label="points")
#----------------------------------------------------------------------------

global_temperatures = [14.4, 14.5, 14.8, 15.2, 15.5, 15.8]
#----------------------------------------------------------------------------

numpirates = [45000, 20000, 15000, 5000, 400, 17]
#----------------------------------------------------------------------------

plot(numpirates, global_temperatures, legend=false)
scatter!(numpirates, global_temperatures, legend=false)
#----------------------------------------------------------------------------

xflip!()
xlabel!("Number of Pirates")
ylabel!("Global Temperature (C)")
title!("Influence of pirate population on global warning")
#----------------------------------------------------------------------------

p1 = plot(x, x)
p2 = plot(x, x.^2)
p3 = plot(x, x.^3)
p4 = plot(x, x.^4)

plot(p1, p2, p3, p4, layout=(2,2), legend=false)
#----------------------------------------------------------------------------

# # Animation

using Plots, ProgressMeter
pyplot(leg=false, ticks=nothing)
x = y = range(-5, stop=5, length=40)
zs = zeros(0,40)
n = 100

## create a progress bar for tracking the animation generation
prog = Progress(n,1)

@gif for i in range(0, stop=2π, length=n)
    f(x,y) = sin(x + 10sin(i)) + cos(y)

    p = plot(x, y, f, st = [:surface, :contourf])

    ## induce a slight oscillating camera angle sweep, in degrees (azimuth, altitude)
    plot!(p[1])

    ## increment the progress bar
    next!(prog)
end
#----------------------------------------------------------------------------
