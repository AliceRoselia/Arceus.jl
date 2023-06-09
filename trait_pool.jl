abstract type TraitPool end


TRAIT_POOL_NAMES= Dict{String,Type{<:TraitPool}}()
TRAIT_POOL_DESCRIPTORS = Dict{Type{<:TraitPool}, PoolDescriptor}()
TRAIT_POOL_TYPES = Dict{Symbol, Type{<:TraitPool}}()
getvalue(trait::TraitPool) = trait.value
setvalue(trait::TraitPool, x::UInt64) = typeof(trait)(x)
macro trait(x)
    return :(error("Trait is not executable.")) 
end

macro trait(x,y)
    return :(error("Trait is not executable."))  
end

macro subpool(x)
    return :(error("Subpool is not executable.")) 
end
macro subpool(x,y)
    return :(error("Subpool is not executable.")) 
end

macro abstract_subpool(x)
    return :(error("Subpool is not executable.")) 
end

macro abstract_subpool(x,y)
    return :(error("Subpool is not executable.")) 
end
#=
macro traitpool(x)
    trait_pool_name = gensym()
    module_name = @__MODULE__
    return esc(:(
        struct $trait_pool_name<:($module_name).TraitPool
            value::UInt64
            $trait_pool_name() = new()
            $trait_pool_name(x) = new(x)
        end;
        ($module_name).TRAIT_POOL_NAMES[$x] = $trait_pool_name #Todo... add module name.
    ))
end
=#


macro traitpool(x,y)
    y = parse_traits(y)
    trait_pool_name = gensym()
    module_name = @__MODULE__

    return esc(:(
        struct $trait_pool_name<:($module_name).TraitPool
            value::UInt64
            $trait_pool_name() = new()
            $trait_pool_name(x) = new(x)
        end;
        ($module_name).TRAIT_POOL_NAMES[$x] = $trait_pool_name;
        ($module_name).TRAIT_POOL_DESCRIPTORS[$trait_pool_name] = $y)
    )
    
end

#Export this.
function get_trait_pool_type(name)
    return TRAIT_POOL_NAMES[name]
end
#For example... this would be.
#=
@traitpool "ABCDEF" begin
    @trait electro
    @trait flame
    @trait laser 2
    @subpool roles begin
        @trait attacker
        @trait support
        
    end
    @subpool meta 16-32 begin
        @trait earlygame
        @trait midgame
        @trait lategame
    end
    @abstract_subpool reserve1 33-48
    @abstract_subpool reserve2 8
end
=#





macro make_traitpool(traitpool, variable)
    var_quot = Meta.quot(variable)
    traitpool_struct = TRAIT_POOL_NAMES[traitpool]
    module_name = @__MODULE__
    eval(:(($module_name).TRAIT_POOL_TYPES[$var_quot] = $traitpool_struct))
    return esc(:($variable = $traitpool_struct(0)))
end

macro make_traitpool(traitpool,variable,traits_set)
    ans = quote
        @make_traitpool $traitpool $variable
        @addtraits $variable $traits_set
        
    end
    return esc(ans)
end

macro register_traitpool(traitpool, variable)
    var_quot = Meta.quot(variable)
    traitpool_struct = TRAIT_POOL_NAMES[traitpool]
    module_name = @__MODULE__
    eval(:(($module_name).TRAIT_POOL_TYPES[$var_quot] = $traitpool_struct))
    return
end

macro copy_traitpool(variable1, variable2)
    module_name = @__MODULE__
    traitpool_struct = TRAIT_POOL_TYPES[variable1]
    var_quot = Meta.quot(variable2)
    eval(:(($module_name).TRAIT_POOL_TYPES[$var_quot] = $traitpool_struct))
    return esc(:($variable2 = $variable1))
end







#End of part 1... defining traits.




