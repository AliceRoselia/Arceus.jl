abstract type TraitPool end


TRAIT_POOL_NAMES= Dict{String,Type{<:TraitPool}}()
TRAIT_POOL_DESCRIPTORS = Dict{Type{<:TraitPool}, PoolDescriptor}()
TRAIT_POOL_TYPES = Dict{Symbol, Type{<:TraitPool}}()
getvalue(trait::TraitPool) = trait.value

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
        ($module_name).TRAIT_POOL_NAMES[$x] = $trait_pool_name;#Todo... add module name.
        ($module_name).TRAIT_POOL_DESCRIPTORS[$trait_pool_name] = $y)
    )
    
end

#For example... this would be.
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

roles = PoolDescriptor(4,5,
    Dict(:(attacker)=>4,:(support)=>5)
)
meta = PoolDescriptor(16,32,
    Dict(:(earlygame)=>16,:(midgame)=>17,:(lategame)=>18)
)
a = PoolDescriptor(1,64, 
Dict(:(electro)=>1,:(laser)=>2,:(flame)=>3, :(roles)=>roles,:(meta)=>meta

)
)





macro make_traitpool(traitpool, variable)
    var_quot = Meta.quot(variable)
    traitpool_struct = TRAIT_POOL_NAMES[traitpool]
    module_name = @__MODULE__
    eval(:(($module_name).TRAIT_POOL_TYPES[$var_quot] = $traitpool_struct))
    return esc(:($variable = $traitpool_struct()))
end

macro clear_context()
    module_name = @__MODULE__
    eval(:(($module_name).TRAIT_POOL_TYPES =  Dict{Symbol, Type{<:TraitPool}}()))
end

@make_traitpool "ABCDEF" Pokemon





#End of part 1... defininig traits.




