using Documenter
using Literate
using Plots # to not capture precompilation output
using Glob
notebooks = glob("*.*.jl")

for notebook in notebooks

    NOTEBOOK   = joinpath(@__DIR__,  notebook)
    MD_OUTPUT  = joinpath(@__DIR__, "markdown")
    NB_OUTPUT  = joinpath(@__DIR__, "notebooks")
   
    Literate.markdown(NOTEBOOK, MD_OUTPUT)
    Literate.notebook(NOTEBOOK, NB_OUTPUT, execute=false)

end

deploydocs(
    deps   = Deps.pip("mkdocs", "python-markdown-math"),
    repo   = "github.com/pnavaro/math-julia.git",
 )
