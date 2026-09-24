# Runs under node against bin/julia.js. Everything here goes through the
# interpreter, so keep it small.

# arithmetic and 32-bit word size
@assert Sys.WORD_SIZE == 32
@assert Int === Int32
@assert Sys.ARCH === :wasm
@assert 2 + 2 == 4
@assert sum(1:100) == 5050

# strings, unicode (libutf8proc) and regular expressions (pcre2)
s = "héllo wörld"
@assert length(s) == 11
@assert uppercase(s) == "HÉLLO WÖRLD"
@assert occursin(r"w.rld", s)
@assert replace(s, r"h(.)llo" => s"H\1LLO") == "HéLLO wörld"

# arbitrary precision integers and floats (gmp / mpfr)
@assert factorial(big(25)) == big"15511210043330985984000000"
@assert string(big(2)^200) == "1606938044258990275541962092341162602522202993782792835301376"
setprecision(BigFloat, 128) do
    @assert abs(BigFloat(pi) - big"3.14159265358979323846264338327950288") < 1e-30
end

# random numbers (dSFMT)
using Random
rng = MersenneTwister(1234)
x = rand(rng, 10)
@assert length(x) == 10 && all(0 .<= x .< 1)
@assert rand(MersenneTwister(1234), 10) == x

# tasks: this exercises the Asyncify fibers
result = Int[]
t = @task (push!(result, 1); yield(); push!(result, 3))
schedule(t)
yield()
push!(result, 2)
wait(t)
@assert result == [1, 2, 3]

# exceptions (emscripten setjmp/longjmp)
caught = try
    error("boom")
catch e
    e isa ErrorException && e.msg == "boom"
end
@assert caught

println("julia wasm test OK: ", VERSION, " on ", Sys.ARCH, "/", Sys.KERNEL)
