using Test, NBInclude

function testnb(nbfile::String)
   try
       @nbinclude(nbfile)
       true
   catch
       false
   end
end

try
   @testset "notebooks" begin
   @test testnb("01.Introduction.ipynb")
   @test testnb("02.Basics.ipynb")
   @test testnb("03.Strings.ipynb")
   @test testnb("04.Data.Types.ipynb")
   @test testnb("05.Control.Flows.ipynb")
   @test testnb("06.Functions.ipynb")
   @test testnb("07.Packages.ipynb")
   @test testnb("08.Plotting.ipynb")
   @test testnb("09.Multiple.Dispatch.ipynb")
   @test testnb("10.LinearAlgebra.ipynb")
   @test testnb("11.Profiling.ipynb")
   @test testnb("12.Structs.ipynb")
   @test testnb("13.Methods.ipynb")
   @test testnb("14.Parallel.Computation.ipynb")
   @test testnb("15.Custom.Arrays.ipynb")
   end
catch
   exit(1)
end
