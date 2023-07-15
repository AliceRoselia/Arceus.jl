mutable struct PoolDescriptor
    isAbstract::Bool
    start::Int
    finish::Int
    args::Dict{Symbol, Union{Int, PoolDescriptor}}

end
PoolDescriptor(x,y,z) = PoolDescriptor(false,x,y,z)

#=
struct IncompletePoolDescriptor
    args::Dict{Symbol, Union{Int, PoolDescriptor,IncompletePoolDescriptor}}
end
=#
abstract type PoolInformation end

abstract type FixedPosPoolInformation<:PoolInformation end
is_fixed_pos(::PoolInformation) = false
is_fixed_pos(::FixedPosPoolInformation) = true

struct TraitInformation <: PoolInformation
    name::Symbol
end
getsize(::TraitInformation) = 1

struct FixedPosTraitInformation<:FixedPosPoolInformation
    name::Symbol
    pos::Int 
end
getsize(::FixedPosTraitInformation) = 1

mutable struct SubPoolInformation <: PoolInformation
    name::Symbol
    args::Vector{PoolInformation}
end
function getsize(x::SubPoolInformation)
    return maximum(final_bit(i) for i in x.args)
end
#getsize(x::SubPoolInformation) = sum(getsize(i) for i in x.args) #Assume organized.

mutable struct FixedPosSubPoolInformation <: FixedPosPoolInformation
    name::Symbol
    start::Int
    finish::Int
    args::Vector{PoolInformation}
end
getsize(x::FixedPosSubPoolInformation) = x.finish-x.start+1

struct AbstractSubPoolInformation <: PoolInformation
    name::Symbol
    size::Int
end
getsize(x::AbstractSubPoolInformation) = x.size

struct FixedPosAbstractSubPoolInformation <: FixedPosPoolInformation
    name::Symbol
    start::Int
    finish::Int
end
getsize(x::FixedPosAbstractSubPoolInformation) = x.finish-x.start+1

final_bit(x::FixedPosAbstractSubPoolInformation) = x.finish
final_bit(x::FixedPosTraitInformation) = x.pos
final_bit(x::FixedPosSubPoolInformation) = x.finish




function remove_line_number_node!(x)
    return 
end


function remove_line_number_node!(x::Expr)
    x.args = [i for i in x.args if !(i isa LineNumberNode)]
    #Base.remove_linenums!(x)
    for i in x.args
        remove_line_number_node!(i)
    end
end


function parsed_trait_args(x)
    @assert x.head == :(macrocall)
    if (x.args[1]) == Symbol("@trait")
        if (length(x.args) == 2)
            return TraitInformation(x.args[2])
        else
            return FixedPosTraitInformation(x.args[2],x.args[3])
        end

    elseif (x.args[1]) == Symbol("@subpool")
        if (x.args[3].head == :block)
            parsed_subpool = parse_traits_first_step(x.args[3])
            return SubPoolInformation(x.args[2],parsed_subpool)
        else
            Temp = x.args[3]
            @assert (Temp.head == :call) && (Temp.args[1] == :(-))
            parsed_subpool = parse_traits_first_step(x.args[4])
            return FixedPosSubPoolInformation(x.args[2],Temp.args[2],Temp.args[3],parsed_subpool)
        end
        #parsed_subpool = parse_traits_first_step(x.args[3].head == :block ? x.args[3] : x.args[4])
    elseif (x.args[1]) == Symbol("@abstract_subpool")
        if (x.args[3] isa Expr)
            Temp = x.args[3]
            @assert (Temp.head == :call) && (Temp.args[1] == :(-))
            return FixedPosAbstractSubPoolInformation(x.args[2],Temp.args[2],Temp.args[3])
        else 
            return AbstractSubPoolInformation(x.args[2],x.args[3])
        end
    end
end

function parse_traits_first_step(traits)
    
    x = [parsed_trait_args(i) for i in traits.args]
    return x
end


function fill_occupied!(i::FixedPosTraitInformation, occupied)
    if (occupied[i.pos])
        error("Cannot organize bits as requested.")
    end
    occupied[i.pos] = true
end

function fill_occupied!(i::FixedPosSubPoolInformation,occupied)
    if (any(occupied[i.start:i.finish]))
        error("Cannot organize bits as requested.")
    end
    occupied[i.start:i.finish] .= true
end

function fill_occupied!(i::FixedPosAbstractSubPoolInformation,occupied)
    if (any(occupied[i.start:i.finish]))
        error("Cannot organize bits as requested.")
    end
    occupied[i.start:i.finish] .= true
end


function occupy_slot!(i::TraitInformation, fixed_pos_pool, occupied)
    #println(occupied)
    for pos in 1:length(occupied)
        if (!occupied[pos])
            occupied[pos] = true
            push!(fixed_pos_pool,FixedPosTraitInformation(i.name,pos))
            return
        end
    end
    error("Cannot organize bits as requested.")
end

function occupy_slot!(i::AbstractSubPoolInformation, fixed_pos_pool, occupied)
    for start in 1:length(occupied)-i.size+1
        finish = start+i.size-1
        if (!any(occupied[start:finish]))
            occupied[start:finish] .= true
            push!(fixed_pos_pool, FixedPosAbstractSubPoolInformation(i.name,start,finish))
            return
        end
    end
    error("Cannot organize bits as requested.")
end

function occupy_slot!(i::SubPoolInformation, fixed_pos_pool, occupied)
    LENGTH = getsize(i)
    for start in 1:length(occupied)-LENGTH+1
        finish = start+LENGTH-1
        if (!any(occupied[start:finish]))
            occupied[start:finish] .= true
            push!(fixed_pos_pool, FixedPosSubPoolInformation(i.name,start,finish,i.args))
            return
        end
    end
    error("Cannot organize bits as requested.")
end

function organize_traits(parsed_pool::Vector{<:PoolInformation}, max_bit = 64)
    for i in parsed_pool
        if (i isa SubPoolInformation)
            i.args = organize_traits(i.args)
        elseif (i isa FixedPosSubPoolInformation)
            i.args = organize_traits(i.args,getsize(i))
        end
    end

    fixed_pos_pools::Vector{FixedPosPoolInformation} = [i for i in parsed_pool if is_fixed_pos(i)]
    dynamic_pos_pools::Vector{PoolInformation} = [i for i in parsed_pool if !is_fixed_pos(i)]
    #println(fixed_pos_pools)
    #println(dynamic_pos_pools)
    occupied = falses(max_bit)
    for i in fixed_pos_pools
        fill_occupied!(i, occupied) 
    end
    for i in dynamic_pos_pools
        occupy_slot!(i,fixed_pos_pools,occupied)
    end

    return fixed_pos_pools
end

function format_traits(organized_traits, start = 1, finish = 64)
    base_pool = PoolDescriptor(start,finish,Dict())
    for i in organized_traits
        if i isa FixedPosTraitInformation
            base_pool.args[i.name] = base_pool.start-1+i.pos
        elseif i isa FixedPosSubPoolInformation
            base_pool.args[i.name] = format_traits(i.args,i.start,i.finish)
        elseif i isa FixedPosAbstractSubPoolInformation
            base_pool.args[i.name] = PoolDescriptor(true,i.start,i.finish,Dict())
        else 
            error("Cannot format trait.")
        end
    end
    return base_pool
end

function parse_traits(traits)
    
    #Case 1: Just traits.
    #Case 2: Trait subpool.
    #Case 3: Traits with position
    #Case 4: Subpools with positions.
    remove_line_number_node!(traits)
    parsed_pool = parse_traits_first_step(traits)
    #parsed_pool = organize_traits(parsed_pool)
    #println(organize_traits(parsed_pool))
    #println(parsed_pool)
    organized_traits = organize_traits(parsed_pool)
    formatted_traits = format_traits(organized_traits)
    #println(formatted_traits)
    return formatted_traits
    #return traits|>dump
end
