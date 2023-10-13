using JuMP
using HiGHS

using PrettyTables

function linear_train_program(A, target; verbose=true)
    #
    # PLEASE FORGIVE THE HORRIBLE VERBOSE TAGGING IT WAS A QUICK HACK FOR BENCHMARKING
    #

    verbose && println(repeat('-', 20))
    verbose && println("Input: $A")
    verbose && println("Target: $(target)")
    model = Model(HiGHS.Optimizer)
    !verbose && set_attribute(model, "log_to_console", false)

    n = length(A)

    """
    Create the n×2 table of parameters s.t. we can only have
    either a num or its inverse
    """
    @variable(model, x[1:n, 1:2], Bin)

    """
    Create the matching table of numbers and their inverse
    """
    c = [[a, -a] for a in A]
    C = reduce(vcat, c')

    """
    Simulate xᵢ₁ ∧ ¬xᵢ₂ by making the sum of each row equal to 1
    """
    cons = map(i->@constraint(model, x[i,1] + x[i,2] == 1), 1:n)
    verbose && println("Boolean constraints:")
    verbose && foreach(println, cons)


    """
    Just helpful organising
    Each row of the "tower" is
        cᵢ⋅xᵢ₁ - cᵢ⋅xᵢ₂ (remember what we defined for x earlier?)
    """
    tower = [C[i,1]*x[i,1] + C[i,2]*x[i,2] for i in 1:n]
    verbose && println("Tower")
    verbose && display(tower)

    """
    The sum of all these expressions should be less than the target (train num)
    """
    con = @constraint(model, sum(tower) <= target)
    verbose && println("Target constraints:")
    verbose && println(con)

    """
    Also maximise the sum of these expressions
    """
    ob = @objective(model, Max, sum(tower))
    verbose && println("Objectives:")
    verbose && println(ob)


    """
    and we're off...
    """
    optimize!(model);

    """

    ...dont read this
    """
    if verbose && has_values(model)
        println(repeat("-", 20))
        s = objective_value(model) == target ? "Train number!" : "No train number :("
        println(s)
        println(repeat("-", 20))
        print(solution_summary(model))
        println("Found: $(objective_value(model))")
        header = ["+", "-", "n"]
        vx = value.(x)
        pos_sum = sum(A .* vx[:,1])
        neg_sum = -sum(A .* vx[:,2])
        total = pos_sum + neg_sum
        data = vcat(hcat(vx, A), [pos_sum, neg_sum, total]')
        hl_p = Highlighter((data, i, j)->(j == 1) && ((data[i,j] == 1) || i == size(data)[1]), crayon"green bold")
        hl_n = Highlighter((data, i, j)->(j == 2) && ((data[i,j] == 1) || i == size(data)[1]), crayon"red bold")
        hl_tf = Highlighter((data, i, j)->(i == size(data)[1]) && (j == 3) && (data[i,j]==target), crayon"yellow bold")
        hl_ts = Highlighter((data, i, j)->(i == size(data)[1]) && (j == 3) && (data[i,j]!=target), crayon"red bold")
        pretty_table(data; header=header, highlighters=(hl_p, hl_n, hl_ts, hl_tf))
    else
        verbose && print(solution_summary(model))
        verbose && display("No solutions :(")
    end
    return model

end

function exampleSuccess()

    linear_train_program([2,2,3,4,1,5,1,2,3,4,6,8,4,1,3,4,5],10,verbose=true);

end

function exampleFail()

    linear_train_program([2,2,3,4,1,5,1,2,3,4,6,8,4,1,3,4,6],10, verbose=true);

end

using BenchmarkTools
function benchmarkIT(n)
    input = rand(1:9, n)
    target = rand(1:n)
    return @benchmark linear_train_program($input, $target, verbose=false)
end

using Combinatorics
function solve_all_four_digits()
    inputs = combinations(1:9, 4)
    targets = [10]
    for target in targets
        for in in inputs

        end
    end
end

