import Base.iterate

abstract type TreeNode end

mutable struct BranchNode <: TreeNode
    children :: Array{BranchNode, 1}
    data::Union{String, LinearClassifier}
    extrainfo::Nothing
end

struct NullNode <: TreeNode
end

struct TreeNodeLeaves{T <: TreeNode}
    node::T
end

const nullnode = NullNode()

function iterate(leaves::TreeNodeLeaves, state::Tuple{Vector{BranchNode}, Vector{Int}})
    function transverse(substate::Tuple{Vector{BranchNode}, Vector{Int}})
        if length(substate[1]) == 0
            return nothing
        end
        current = pop!(substate[1])
    
        if length(current.children) == 0
            println(current.data)
            println(substate[2])
            return ((current.data, copy(substate[2])), substate)
        end
        for index = eachindex(current.children)
            nextnode = current.children[index]
            push!(substate[1], nextnode)
            push!(substate[2], index)
            transverse(substate)
            pop!(substate[2])
        end
    end
    return transverse(state)
end


# function iterate(leaves::TreeNodeLeaves, state::Tuple{Vector{BranchNode}, Vector{Int}})
#     if length(state[1]) == 0
#         return nothing
#     end
#     current = popfirst!(state[1])

#     if length(current.children) == 0
#         return ((current.data, copy(state[2])), state)
#     end

#     for index = eachindex(current.children)
#         nextnode = current.children[index]
#         push!(state[1], nextnode)
#         push!(state[2], index)
#     end
#     return iterate(leaves, state)
# end

function iterate(leaves::TreeNodeLeaves)
    nodes = Vector{BranchNode}()
    indices = Int[]
    
    push!(nodes, leaves.node)

    return iterate(leaves, (nodes, indices))
end

function leaves_of(root::TreeNode)
    code = Int[]
    function traverse(node::TreeNode, c::Channel)
        if node == nullnode
            return
        end
        if length(node.children) == 0
            put!(c, (node.data, copy(code)))    # notice that we should copy the current state of code
        end
        for index = eachindex(node.children)
            child = node.children[index]
            push!(code, index)
            traverse(child, c)
            pop!(code)
        end
    end
    return Channel((channel_arg) -> traverse(root, channel_arg))
end

function internal_nodes_of(root::TreeNode)
    function traverse(node::TreeNode)
        if node == nullnode
            return
        end
        if length(node.children) != 0
            produce(node)
        end
        for child in node.children
            traverse(child)
        end
    end
    Task(() -> traverse(root))
end

function average_height(tree::TreeNode)
    (h, c) = (0, 0)
    for (_, path) in leaves_of(tree)
        h += length(path)
        c += 1
    end
    h / c
end
