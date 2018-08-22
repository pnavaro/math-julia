module NBTest

using NBInclude

export hello, domath
export testnb

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

end # module
