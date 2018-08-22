using Pkg
io = open("REQUIRE", "r")
deps = read(io, String)
for dep in split(deps)
   Pkg.add(String(dep))
end
