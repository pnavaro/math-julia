
# # Create your Julia package
# 
# ## New repository on Github
# 
# https://github.com/pnavaro/Example.jl
# 
# - The repository name has the ".jl" extension
# 
# 
# ## Create the package on your computer
# 
# ```julia
# julia> using Pkg
# julia> Pkg.generate("Example")
# ```
# 
# ## Push the package on github
# 
# ```bash
# cd Example
# echo "# Example.jl" >> README.md
# git init
# git add README.md
# git commit -m "first commit"
# git remote add origin git@github.com:pnavaro/Example.jl.git
# git push -u origin master
# ```
# 
# ## On Github 
# 
# Above the file list, click Create new file.
# 
# In the file name field, type LICENSE (with all caps).
# 
# - Choose a license template button.
# - Click Choose a license template.
# - Add a license to your project.
# - Don't create pull request choose "master" branch.
# 
# ## On your computer
# 
# ```bash
# git pull origin master
# ```
# 
# ## The Example.jl module
# 
# ```julia
# module Example
# 
# greet() = print("Hello World!")
# 
# export add
# 
# function add( x , y)
#     x + y
# end
# 
# end # module
# ```
# 
# ## Add a test
# 
# ```bash
# cd Example
# mkdir test
# ```
# 
# add file runtests.jl
# ``julia
# using Test
# using Example
# 
# @testset " Test function add "
# 
# @test add( 1, 2) == 3
# 
# end
# ```
# 
# ## Verify the test
# 
# ```bash
# cd Example
# julia> ]
# (v1.0) pkg> activate .
# ```
# 
# ```juliarepl
# (Example) pkg> test
#    Testing Example
#  Resolving package versions...
# Test Summary:       | Pass  Total
#  Test function add  |    1      1
#    Testing Example tests passed 
# ```
# 
# ## Documentation
# 
# https://github.com/JuliaDocs/Documenter.jl
# 
# Document the function add
# 
# ```julia
# """
#     add( x, y)
# 
# Add two variables and return the result
# 
# """
# function add( x , y)
#     x + y
# end
# ```
# 
# - Create docs directory
# - add docs/src/index.md file with
# 
# ~~~
# # Example.jl Documentation
# 
# ## Types and Functions
# 
# ```@autodocs
# Modules = [Example]
# Order   = [:type, :function]
# ```
# 
# ~~~

# - Push changes to github
# - add docs/build in .gitignore
# - add Manifest.toml also
# 
# 
# 
# 
# - Create `docs/make.jl` file
# 
# ```julia
# push!(LOAD_PATH,"../src/")
# 
# using Example
# using Documenter
# 
# makedocs(modules=[Example],
#          doctest = false,
#          format = :html,
#          sitename = "Example.jl",
#          pages = ["Documentation"    => "index.md"])
# 
# deploydocs(
#     deps   = Deps.pip("mkdocs", "python-markdown-math"),
#     repo   = "github.com/pnavaro/Example.jl.git",
#  )
# ```
# 
# - Install first version of Example package in your julia installation
# 
# ```julia
# (v1.0) pkg> add https://github.com/pnavaro/Example.jl.git
# ```
# 
# - Test it
# ```bash
# cd docs
# julia make.jl
# ```

# # Travis
# 
# https://travis-ci.org
# 
# - Profile -> Settings
# - 
# 
