# Interface to AbstractTrees.jl
AbstractTrees.children(node::RuleNode) = node.children
AbstractTrees.printnode(io::IO, node::RuleNode) = print(io, node.ind)


"""
Returns the minimum depth achievable for each production rule, dmap.
"""
function mindepth_map(grammar::Grammar)
    dmap0 = Int[isterminal(grammar,i) ? 0 : typemax(Int)/2 for i in eachindex(grammar.rules)]
    dmap1 = fill(-1, length(grammar.rules)) 
    while dmap0 != dmap1
        for i in eachindex(grammar.rules)
            dmap1[i] = _mindepth(grammar, i, dmap0)
        end
        dmap1, dmap0 = dmap0, dmap1
    end
    dmap0
end


function _mindepth(grammar::Grammar, rule_index::Int, dmap::AbstractVector{Int})
    isterminal(grammar, rule_index) && return 0
    return 1 + maximum([mindepth(grammar, ctyp, dmap) for ctyp in child_types(grammar, rule_index)])
end


"""
Returns the minimum depth achievable for a given nonterminal symbol
"""
function mindepth(grammar::Grammar, typ::Symbol, dmap::AbstractVector{Int})
    return minimum(dmap[grammar.bytype[typ]])
end

const SymbolTable = Dict{Symbol,Any}

"""
Returns a symbol table populated with mapping from symbols in grammar to
symbols in module mod or Main, if defined.
"""
function Grammars.SymbolTable(grammar::Grammar, mod::Module=Main)
    tab = SymbolTable()
    for rule in grammar.rules
        _add_to_symboltable!(tab, rule, mod)
    end
    tab
end


_add_to_symboltable!(tab::SymbolTable, rule::Any, mod::Module) = true


function _add_to_symboltable!(tab::SymbolTable, rule::Expr, mod::Module)
    if rule.head == :call && !iseval(rule)
        s = rule.args[1]
        if !_add_to_symboltable!(tab, s, mod)
            @warn "Unable to add function $s to symbol table"  
        end
        for s in rule.args[2:end]  #nested exprs
            _add_to_symboltable!(tab, s, mod)
        end
    end
    return true
end


function _add_to_symboltable!(tab::SymbolTable, s::Symbol, mod::Module)
    if isdefined(mod, s)
        tab[s] = getfield(mod, s)
        return true
    elseif isdefined(Base, s)
        tab[s] = getfield(Base, s)
        return true
    elseif isdefined(Main, s)
        tab[s] = getfield(Main, s)
        return true
    else
        return false
    end
end


"""
Checks if elements of vec1 are contained in vec2 in the same order (possibly with elements in between)
"""
function containedin(vec1::Vector, vec2::Vector)
	max_elements = length(vec1)
	vec1_index = 1 # keeps track where we are in the first vector
	for item in vec2
		if vec1_index > max_elements
			return true
		end
		
		if item == vec1[vec1_index]
			vec1_index += 1  # increase the index every time we encounter the matching element
		end
	end

	return vec1_index > max_elements
end


"""
Checks if vec1 is a subsequence of vec2
"""
function subsequenceof(vec1::Vector{Int}, vec2::Vector{Int})
    vec1_index = 1
    last_found_vec1_element_ind = 0
    vec2_index = 1

    while isassigned(vec2, vec2_index)
        vec2_elem = vec2[vec2_index]
        vec1_elem = get(vec1, vec1_index, nothing)

        if vec1_elem === nothing 
            break
        end

        if vec1_elem == vec2_elem && (last_found_vec1_element_ind == 0 || last_found_vec1_element_ind == vec2_index - 1)
            vec1_index += 1
            last_found_vec1_element_ind = vec2_index
        end

        vec2_index += 1
    end
    
    return get(vec1, vec1_index, nothing) === nothing

end


"""
Returns true if the node has children
"""
has_children(rule::RuleNode) = !isempty(rule.children)


