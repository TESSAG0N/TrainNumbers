include("../src/TrainNumbers.jl")

using Combinatorics

using Random
using BenchmarkTools


function benchmarkIT(n)
    input = rand(1:9, n)
    target = rand(1:n)
    return @benchmark TrainNumbers.linearAlgSolveReducedTrainGame($input, $target)
end

