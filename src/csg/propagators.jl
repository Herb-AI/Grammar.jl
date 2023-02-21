
"""
Propagates the ComesAfter constraint.
It removes the rule from the domain if the predecessors sequence is in the ancestors.
"""
function propagate(c::ComesAfter, context::GrammarContext, domain::Vector{Int})
	ancestors = get_rulesequence(context.originalExpr, context.nodeLocation[begin:end-1])  # remove the current node from the node sequence
	if c.rule in domain  # if rule is in domain, check the ancestors
		if containedin(c.predecessors, ancestors)
			return domain
		else
			return filter(e -> e != c.rule, domain)
		end
	else # if it is not in the domain, just return domain
		return domain
	end
end

function propagate_index(c::ComesAfter, context::GrammarContext, domain::Vector{Int})
	ancestors = get_rulesequence(context.originalExpr, context.nodeLocation[begin:end-1])  # remove the current node from the node sequence
	if c.rule in domain  # if rule is in domain, check the ancestors
		if containedin(c.predecessors, ancestors)
			return 1:length(domain)
		else
			return reduce((acc, x) -> (!(x[2] == c.rule) ? push!(acc, x[1]) : acc), enumerate(domain); init=Vector{Int}())
		end
	else # if it is not in the domain, just return domain
		return 1:length(domain)
	end	
end


"""
Propagates the Ordered constraint.
It removes every element from the domain that does not have a necessary 
predecessor in the left subtree.
"""
function propagate(c::Ordered, context::GrammarContext, domain::Vector{Int})
	rules_on_left = rulesonleft(context.originalExpr, context.nodeLocation)
	
	last_rule_index = 0
	for r in c.order
		r in rules_on_left ? last_rule_index = r : break
	end

	rules_to_remove = Set(c.order[last_rule_index+2:end]) # +2 because the one after the last index can be used

	return filter((x) -> !(x in rules_to_remove), domain) 
end

function propagate_index(c::Ordered, context::GrammarContext, domain::Vector{Int})
	rules_on_left = rulesonleft(context.originalExpr, context.nodeLocation)
	
	last_rule_index = 0
	for r in c.order
		r in rules_on_left ? last_rule_index = r : break
	end

	rules_to_remove = Set(c.order[last_rule_index+2:end]) # +2 because the one after the last index can be used

	return reduce((acc, x) -> (!(x[2] in rules_to_remove) ? push!(acc, x[1]) : acc), enumerate(domain); init=Vector{Int}()) 
end


"""
Propagates the Forbidden constraint.
It removes the elements from the domain that would complete the forbidden sequence.
"""
function propagate(c::Forbidden, context::GrammarContext, domain::Vector{Int})
	ancestors = get_rulesequence(context.originalExpr, context.nodeLocation[begin:end-1])
	
    if subsequenceof(c.sequence[begin:end-1], ancestors)
		last_in_seq = c.sequence[end]
		return filter(x -> !(x == last_in_seq), domain)
	end

	return domain
end

function propagate_index(c::Forbidden, context::GrammarContext, domain::Vector{Int})
	ancestors = get_rulesequence(context.originalExpr, context.nodeLocation[begin:end-1])
	
    if subsequenceof(c.sequence[begin:end-1], ancestors)
		last_in_seq = c.sequence[end]
		return reduce((acc, x) -> (!(x[2] == last_in_seq) ? push!(acc, x[1]) : acc), enumerate(domain); init=Vector{Int}())
	end

	return 1:length(domain)
end