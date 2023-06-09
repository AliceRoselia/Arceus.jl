

function parse_subpool_source(x::Expr)
    @assert x.head == Symbol(".")
    a,b = parse_subpool_source(x.args[1])
    push!(b,x.args[2].value)
    return a,b
end

function parse_subpool_source(x::String)
    return x, Vector{Symbol}()
end


#=
mutable struct PoolDescriptor
    isAbstract::Bool
    start::Int
    finish::Int
    args::Dict{Symbol, Union{Int, PoolDescriptor}}

end
=#


#Name varname to be subpool of a pool or subpool walking down from parent.
macro subpool(subpool,source, traitsset::Expr)
    module_name = @__MODULE__
    #trait_pool_type = get_trait_pool_type(source.args[1])
    
    #println(traitsset|>dump)
    #Walk_trait in trait_pool_descriptor 
    trait_pool_name, trait_pool_walk = parse_subpool_source(source)
    trait_pool_type = get_trait_pool_type(trait_pool_name)
    trait_pool_descriptor = module_name.TRAIT_POOL_DESCRIPTORS[trait_pool_type]
    trait_pool_walk, next_dest = trait_pool_walk[1:end-1], trait_pool_walk[end]
    Pool_gotten::PoolDescriptor = walk_trait_pool_descriptor(trait_pool_walk,trait_pool_descriptor)
    @assert Pool_gotten.isAbstract
    SIZE = Pool_gotten.finish-Pool_gotten.start+1
    #println(:($Pool_gotten))
    remove_line_number_node!(traitsset)
    parsed_traits = parse_traits_first_step(traitsset) 
    organized_traits = organize_traits(parsed_traits,SIZE)
    #println(format_traits(organized_traits,Pool_gotten.start,Pool_gotten.finish))
    Pool_gotten.args[next_dest] = format_traits(organized_traits,Pool_gotten.start,Pool_gotten.finish)
    #println(organized_traits)



    #We need to return the subpool information and type.
    return

    #For abstract subpools.
    #To be finished... parsed traits should only take the amount of bits allocated.

end
macro subpool(subpool,source)
    #For normal subpools.
    #No need to alter the pool descriptor, but must return the subpool information and type.
end

macro make_subpool(subpool, variable, parent::Symbol)

end

macro make_subpool(subpool, variable, traitsset::Expr)

end

macro register_subpool(subpool,variable)
    #println(subpool)
    #println(variable)
end

macro join_subpools(subpools)

end

macro join_subpools(base_pool, subpools)

end


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

@make_traitpool "ABCDEF" Pokemon begin
    @trait electro
    @trait flame
end
@subpool "Biome" "ABCDEF".reserve1.biome_preference begin
    @trait beach_preference
    @trait ice_preference
    @trait volcanic_preference
end
@subpool "Meta" "ABCDEF".meta

@make_subpool "Biome" biometraits Pokemon
@make_subpool "Meta" metatraits Pokemon
@make_subpool "Biome" biometraits2 begin
    @trait beach_preference 1
    @trait ice_preference 0
    @trait volcanic_preference
end

@register_subpool "Biome" biometraits3

@join_subpools Pokemon begin
    @subpool biometraits2
    @subpool metatraits
end