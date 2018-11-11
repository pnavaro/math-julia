
# 
# ## Packages
# 
# https://pkg.julialang.org or https://juliaobserver.com

using Pkg
Pkg.add("Example")
#----------------------------------------------------------------------------

using Example
#----------------------------------------------------------------------------

?Example
#----------------------------------------------------------------------------

# ```julia
# module Example
# export hello, domath
# 
# hello(who::String) = "Hello, $who"
# domath(x::Number) = x + 5
# 
# end
# ```

using Colors
#----------------------------------------------------------------------------

palette = distinguishable_colors(100)
#----------------------------------------------------------------------------

module MyModule

export x, y

x() = "x"
y() = "y"
p() = "p"

end
#----------------------------------------------------------------------------

# <table>
#     <tr>
#         <td><b>Import Command</b></td>
#         <td><b>What is brought into scope</b></td>
#         <td><b>Available for method extension</b></td>
#     </tr>
#     <tr>
#         <td>using MyModule</td>
#         <td>All exported names (x and y), MyModule.x, MyModule.y and MyModule.p</td>
#         <td>MyModule.x, MyModule.y and MyModule.p</td>
#     </tr>
#     <tr>
#         <td>using MyModule: x, p</td>
#         <td>x and p</td>
#         <td></td>
#     </tr>
#     <tr>
#         <td>using MyModule</td>
#         <td>MyModule.x, MyModule.y and MyModule.p</td>
#         <td>MyModule.x, MyModule.y and MyModule.p</td>
#     </tr>
#     <tr>
#         <td>import MyModule.x, MyModule.p</td>
#         <td>x and p</td>
#         <td>x and p</td>
#     </tr>
#     <tr>
#         <td>import MyModule: x, p</td>
#         <td>x and p</td>
#         <td>x and p</td>
#     </tr>
#     </table>
