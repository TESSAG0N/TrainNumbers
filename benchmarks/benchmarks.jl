using BenchmarkTools
using Random
using Plots
using StatsPlots
using LinearAlgebra

using CPUSummary

Random.seed!(2000)
include("../src/TrainNumbers.jl")

using Octavian

TN = TrainNumbers;

function oldBenchmark()
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
        suite["Iterables"]["length $i", join(repr.(ops))] = @benchmarkable batchTest($vec,10, $ops);
    end

    tune!(suite)
    results = run(suite)

    plot(results)

end

plotly()
function compareLinearSolvers()
    display("Threads: $(Base.Threads.nthreads())")
    nrange = 1:10
    target = 10
    collectnew = []
    collectold = []
    for n in nrange
        m = TN.createCountingMatrix(n)
        display("n=$n target=$target")
        new = @benchmark TN.solveForAll($n, $target, m=$m)
        old = @benchmark TN.solveForAllOld($n,$target, m=$m)

        mew = median(new)
        mold = median(old)

        push!(collectnew, mew.time)
        push!(collectold, mold.time)

        display(mold)
        display(mew)
        display(judge(mew, mold))
    end
    return scatter!(nrange, [collectnew, collectold], label=["new" "old"])
end

out = compareLinearSolvers()
display(out)
