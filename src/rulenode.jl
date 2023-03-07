"""
Type for representing expression trees.
"""
abstract type AbstractRuleNode end


"""
RuleNode
Type for representing nodes in an expression tree.
"""
mutable struct RuleNode <: AbstractRuleNode
	ind::Int # index in grammar
	_val::Any  #value of _() evals
	children::Vector{AbstractRuleNode}
end

mutable struct Hole <: AbstractRuleNode
	domain::BitVector
end

RuleNode(ind::Int) = RuleNode(ind, nothing, AbstractRuleNode[])
RuleNode(ind::Int, children::Vector{AbstractRuleNode}) = RuleNode(ind, nothing, children)
RuleNode(ind::Int, children::Vector{RuleNode}) = RuleNode(ind, nothing, children)
RuleNode(ind::Int, children::Vector{Hole}) = RuleNode(ind, nothing, children)
RuleNode(ind::Int, _val::Any) = RuleNode(ind, _val, AbstractRuleNode[])
RuleNode(ind::Int, grammar::Grammar) = RuleNode(ind, nothing, [Hole(get_domain(grammar, type)) for type ∈ grammar.childtypes[ind]])
RuleNode(ind::Int, _val::Any, grammar::Grammar) = RuleNode(ind, _val, [Hole(get_domain(grammar, type)) for type ∈ grammar.childtypes[ind]])

include("recycler.jl")
    
Base.:(==)(::RuleNode, ::Hole) = false
Base.:(==)(::Hole, ::RuleNode) = false
Base.:(==)(A::RuleNode, B::RuleNode) = 
	(A.ind == B.ind) && 
	length(A.children) == length(B.children) && #required because zip doesn't check lengths
	all(isequal(a, b) for (a, b) ∈ zip(A.children, B.children))
Base.:(==)(A::Hole, B::Hole) = A.domain == B.domain

function Base.hash(node::RuleNode, h::UInt=zero(UInt))
	retval = hash(node.ind, h)
	for child in node.children
		retval = hash(child, retval)
	end
	return retval
end

function Base.hash(node::Hole, h::UInt=zero(UInt))
	return hash(node.domain, h)
end

function Base.show(io::IO, node::RuleNode; separator=",", last_child::Bool=false)
	print(io, node.ind)
	if !isempty(node.children)
	    print(io, "{")
	    for (i,c) in enumerate(node.children)
		show(io, c, separator=separator, last_child=(i == length(node.children)))
	    end
	    print(io, "}")
	elseif !last_child
	    print(io, separator)
	end
end

function Base.show(io::IO, node::Hole; separator=",", last_child::Bool=false)
	print(io, "hole[$(node.domain)]")
	if !last_child
		print(io, separator)
	end
end

"""
Return the number of vertices in the tree rooted at root.
Holes don't count.
"""
function Base.length(root::RuleNode)
	retval = 1
	for c in root.children
	    retval += length(c)
	end
	return retval
end

"""
Return the number of vertices in the tree rooted at root.
Holes don't count.
"""
Base.length(::Hole) = 0


"""
Return the depth of the expression tree rooted at root.
Holes don't count.
"""
function depth(root::RuleNode)
	retval = 1
	for c in root.children
	    retval = max(retval, depth(c)+1)
	end
	return retval
end


"""
Return the depth of the expression tree rooted at root.
Holes don't count.
"""
depth(::Hole) = 0


"""
Return the depth of node for an expression tree rooted at root. 
Depth is 1 when root == node.
"""
function node_depth(root::AbstractRuleNode, node::AbstractRuleNode)
	root === node && return 1
	root isa Hole && return 0
	for c in root.children
	    d = node_depth(c, node)
	    d > 0 && (return d+1)
	end
	return 0
end
