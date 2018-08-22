using Pkg

function install_deps()
   io = open("REQUIRE", "r")
   deps = read(io, String)
   
   for dep in split(deps)
      Pkg.add(String(dep))
   end
end

function write_tests()

   nbfiles = glob("*.ipynb")
   
   header = """
using Test, NBInclude

function testnb(nbfile::String)
   try
       @nbinclude(nbfile)
       true
   catch
       false
   end
end

"""

   open("runtests.jl", "w") do f
   
      write(f,  header)
      write(f,"@testset \"notebooks\" begin\n"
   
      for nbfile in nbfiles
         write(f, "@test testnb(\"$nbfile\")\n")
      end
      
      write(f,"end;")
   
   end

end

install_deps()
using Glob
write_tests()
