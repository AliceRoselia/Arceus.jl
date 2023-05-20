abstract type TraitPool end
TRAIT_POOL_NAMES= Dict{String,Type{<:TraitPool}}()
getvalue(trait::TraitPool) = trait.value


macro traitpool(x)
    trait_pool_name = gensym()
    return esc(:(
        struct $trait_pool_name<:TraitPool
            value::UInt64
            $trait_pool_name() = new()
            $trait_pool_name(x) = new(x)
        end;
        TRAIT_POOL_NAMES[$x] = $trait_pool_name 
    ))
end



macro make_traitpool(traitpool, variable)
    traitpool_struct = TRAIT_POOL_NAMES[traitpool]
    return esc(:($variable = $traitpool_struct()))
end

@traitpool "ABC"
@make_traitpool "ABC" X

println(getvalue(X))