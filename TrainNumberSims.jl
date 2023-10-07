# Train number input space
# 4 Numbers {a, b, c, d} drawn from single digit integers x in [0...9]
#
using Combinatorics
using AbstractTrees


operations = [+, -, *, /, ^]

#const operations = [
#    (x,y) -> x + y
#    (x,y) -> x - y
#    (x,y) -> x / y
#    (x,y) -> x * y
#]


mutable struct Node
    val::Union{Float64, Nothing}
    l::Union{Node, Nothing}
    r::Union{Node, Nothing}
    op::Union{Function, Nothing}
end

function Node()
    return Node(0,nothing,nothing)
end
function Node(x::Int)
    return Node(x, nothing, nothing)
end
function Node(x, l, r)
    return Node(x, l, r, nothing)
end

AbstractTrees.children(n::Node) = [n.l, n.r]
AbstractTrees.nodevalue(n::Node) = (n.val, n.op)

function myprintnode(io::IO, node; kw...)
    print("$(node.val) ($(repr(node.op)))")
end
function myprintchildkey(io::IO, node; kw...)
    print("$(node.l) $(node.r)")
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

function attemptAllOperation(tree, operations, nleaves, target=nothing)
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
