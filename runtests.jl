using Test, NBInclude

hello(who::String) = "Hello, $who"
domath(x::Number) = x + 5

function testnb(nbfile::String)
   try
       @nbinclude(nbfile)
       true
   catch
       false
   end
end

@test hello("Julia") == "Hello, Julia"
@test domath(2.0) ≈ 7.0
@test testnb("01.Introduction.ipynb")
#@test testnb("02.Basics.ipynb")
