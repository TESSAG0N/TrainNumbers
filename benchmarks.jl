using BenchmarkTools
using Random
Random.seed!(2000)
include("TrainNumberSims.jl")

suite = BenchmarkGroup()

ops = [+,-,*,/,^]

suite["Iterables"] = BenchmarkGroup([join(repr.(ops))])
show(suite)


v(n) = [rand(1:9, n) for _ in 1:50]

function batchTest(vec, t, o)
    for v in vec
        quickSolve(v, t, o)
    end
end

for i in 1:10
    vec = v(i)
    suite["Iterables"]["length", i, join(repr.(ops))] = @benchmarkable batchTest($vec,10, $ops);
end

tune!(suite)
results = run(suite)

plot(results)

