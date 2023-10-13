# Train number input space
# 4 Numbers {a, b, c, d} drawn from single digit integers x in [0...9]
#

module TrainNumbers

using Combinatorics
using AbstractTrees


operations = [+, -, *, /]

mutable struct Node
    val::Union{Float64, Nothing}
    l::Union{Node, Nothing}
    r::Union{Node, Nothing}
    op::Union{Function, Nothing}
end

function Node()
    return Node(0,nothing,nothing)
end
function Node(x)
    return Node(x, nothing, nothing)
end
function Node(x, l, r)
    return Node(x, l, r, nothing)
end

AbstractTrees.children(n::Node) = begin
    leaf = all(isnothing([n.l,n.r]))
    return leaf ? nothing : [n.l, n.r]
end
AbstractTrees.nodevalue(n::Node) = begin
    leaf = all(isnothing([n.l,n.r]))
    return leaf ? n.val : (n.val, n.op)
end

function AbstractTrees.printnode(io::IO, p::Node)
    leaf = all(isnothing(AbstractTrees.children(p)))
    str = leaf ? string(p.val) : string(p.val, ", ", string(p.op))
    print(io, str)
end

function AbstractTrees.print_child_key(io::IO, k)
    leaf = all(isnothing(AbstractTrees.children(k)))
    str = leaf ? "" : k.val
    print(io, str)
end

function allPossibleFBT(n)
    result = Node[]
    if n == 1
        push!(result, Node())
    end

    for i in 1:2:n-1
        left = allPossibleFBT(i)
        right = allPossibleFBT(n-i)
        for l in left
            for r in right
                root = Node(0, l, r)
                push!(result, root)
            end
        end
    end
    return result
end

using ResumableFunctions
@resumable function BSTGenerator(v)
    n = length(v)
    result = Node[]
    if n == 1
        push!(result, Node(v[n]))
    end
    for i in 1:2:n-1
        left = allPossibleFBTvec(v[begin:i])
        right = allPossibleFBTvec(v[i+1:end])
        for l in left
            for r in right
                root = Node(nothing, l, r)
                @yield root
            end
        end
    end
end

function allPossibleFBTvec(v)
    n = length(v)
    result = Node[]
    if n == 1
        push!(result, Node(v[n]))
    end
    for i in 1:2:n-1
        left = allPossibleFBTvec(v[begin:i])
        right = allPossibleFBTvec(v[i+1:end])
        for l in left
            for r in right
                root = Node(nothing, l, r)
                push!(result, root)
            end
        end
    end
    return result
end

function postOrderTraversal!(root, opStack)
    if isnothing(root.l) && isnothing(root.r)
        return root, opStack
    end
    (l, opStack) = postOrderTraversal!(root.l, opStack)
    (r, opStack) = postOrderTraversal!(root.r, opStack)
    if isnothing(root.val)
        op = pop!(opStack)
        root.op = op
        root.val = op(l.val, r.val)
    end
    return root, opStack
end

@resumable function attemptAllOperationIter(tree, operations, nleaves)
    n = 2*nleaves - 1
    op_generator = with_replacement_combinations(operations, n)
    for ops in op_generator
        t = deepcopy(tree)
        (ret, _) = postOrderTraversal!(t, ops)
        @yield ret
    end
end
"""
Check this out!
"""
function for_example(v=[2,2,3,4,5,6], target=10, operations=[+,-,*,/])
    for tree in BSTGenerator(v)
        for solve in attemptAllOperationIter(tree, operations, length(v))
            if solve.val == target
                print_tree(solve, maxdepth=16)
                return solve
            end
        end
    end
end

function quickSolve(v=[2,2,3,4,5,6], target=10, operations=[+,-,*,/])
    for tree in BSTGenerator(v)
        for solve in attemptAllOperationIter(tree, operations, length(v))
            if solve.val == target
                return solve
            end
        end
    end
    return nothing
end

function attemptAllOperation(tree, operations, nleaves)
    n = nleaves
    k = length(operations)
    op_generator = with_replacement_combinations(operations, n-1)

    forest = [deepcopy(tree) for _ in 1:binomial(n+k-1, n)]
    operator_results = sizehint!(Tuple{String, Float64}[], binomial(n+k-1, n))
    for (ops,t) in zip(op_generator, forest)
        combo = join([repr(o) for o in ops])
        (ret, finalOps) = postOrderTraversal!(t, ops)
        if length(finalOps) != 0
            println("final ops weird")
            println(finalOps)
            print_tree(t)
        end
        push!(operator_results, (combo, ret.val))
    end
    return forest
end

function solve_train_number(target, inputs, operations)
    nleaves = length(inputs)
    possible_trees = allPossibleFBTvec(inputs)
    outs = [attemptAllOperation(t, operations, nleaves) for t in possible_trees]

    solutions = []
    for out in Iterators.flatten(outs)
        if out.val == target
            println("Solution found!")
            print_tree(out)
            push!(solutions, out)
        end
    end
    println("No solution found!")
    return solutions
end

function quick_solve_train_number(target, inputs, operations)
    nleaves = length(inputs)
    possible_trees = allPossibleFBTvec(inputs)
    outs = [attemptAllOperation(t, operations, nleaves) for t in possible_trees]

    for out in Iterators.flatten(outs)
        if out.val == target
            return true
        end
    end
    return false
end

function showTree(n, indent=0)
    spacing = repeat("    ", indent)
    if isnothing(n.l) && isnothing(n.r)
        printstyled(spacing * "Node($(n.val))", color=indent+1)
        println()
    else
        if isnothing(n.op)
            printstyled(spacing * "Node($(n.val),",color=indent+1)
        else
            printstyled(spacing * "Node($(n.val) $(repr(n.op)),", color=indent+1)
        end
        println()
        showTree(n.l, indent+1)
        showTree(n.r, indent+1)
        printstyled(spacing * ")",color=indent+1)
        println()
    end
end

using Plots; plotly()
function nutsPlot(operations=operations)

    inputs = [[a,b,c] for a in 0:0.1:9 for b in 0:9 for c in 0:9]

    outputs = filter!(x->quick_solve_train_number(10, x, operations), inputs)

    X = [c[1] for c in outputs]
    Y = [c[2] for c in outputs]
    Z = [c[3] for c in outputs]

    return scatter(X,Y,Z)

end

function get_tree_as_maths(tree, root=true)::String
    if isnothing(tree.l) && isnothing(tree.r)
        return repr(tree.val)
    end
    lhs = repr(tree.val)
    rhs = "(" * get_tree_as_maths(tree.l, false) * repr(tree.op) * get_tree_as_maths(tree.r, false) * ")"
    if root
        return lhs * "=" * rhs
    else
        return rhs
    end
end

function quick_solver(input::String, operations=operations, target=10)


    v = try
            [parse(Int, x) for x in split(input, "")]
        catch
            println("Invalid input!")
            return
        end
    println(v)

    solved = nothing
    for tree in BSTGenerator(v)
        for solve in attemptAllOperationIter(tree, operations, length(v))
            if solve.val == target
                solved = solve
            end
        end
    end
    if !isnothing(solved)
        println(get_tree_as_maths(solved))
        print_tree(solved, maxdepth=16)
    else
        println("No solution found!")
    end

end

function createCountingMatrix(n)
    m = map.(x->iszero(x) ? -1 : 1, [digits(i, base=2, pad=n) for i in 0:2^n-1])
    return reduce(hcat, m)'
end


function AdditiveSolutions(n, target; m=createCountingMatrix(n))
    inputs = collect(with_replacement_combinations(collect(0:9), n))
    outputs = filter(x->any(==(target), m*x), inputs)
    if isempty(outputs)
        return Matrix{}(undef,0,0)
    end
    return reduce(hcat, outputs)
end

function addSubtractOuts(x;m=createCountingMatrix(length(x)))
    return m*x
end
function getOutsFromMatrix(o)
    X = o[1,:]
    Y = o[2,:]
    Z = o[3,:]
    return (X,Y,Z)
end

function linearAlgSolveReducedTrainGame(a, target)
    n = length(a)
    m = createCountingMatrix(n)
    return any(==(target), m*a)
end

#[module TrainNumbers]
end
