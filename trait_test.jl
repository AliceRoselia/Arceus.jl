macro hastrait(expression)
    #println(parse_walk_chain(expression))
    Temp = parse_walk_chain(expression)
    varname = Temp[1]
    walk = Temp[2:end]
    trait_pool_descriptor = get_trait_pool_descriptor(varname)
    traitnum = walk_trait_pool_descriptor(walk,trait_pool_descriptor)
    trait_bit = UInt64(1)<<(traitnum-1)
    return esc(:(!iszero(getvalue($varname)&($trait_bit))))
end

macro usetrait(expression)
    return nothing
end