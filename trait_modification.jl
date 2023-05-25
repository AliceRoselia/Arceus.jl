


function get_trait_pool_descriptor(variable)
    module_name = @__MODULE__
    trait_pool_type = module_name.TRAIT_POOL_TYPES[variable]
    trait_pool_descriptor = module_name.TRAIT_POOL_DESCRIPTORS[trait_pool_type]
    return trait_pool_descriptor
end

function parse_walk_chain(chain::Symbol)
    return [chain]
end

function parse_walk_chain(chain::Expr)
    @assert chain.head == Symbol(".")
    return vcat(parse_walk_chain(chain.args[1]),parse_walk_chain(chain.args[2].value))
end

function parse_individual_trait_mod_arg(x)
    @assert x.head == :macrocall && x.args[1] == Symbol("@trait")
    walking_chain = parse_walk_chain(x.args[2])
    #if (length{x.args} >= 3)
    value = length(x.args) >= 3 ? x.args[3] : 1
    #println(walking_chain)
    return (walking_chain,value)
end

struct traitsArguments
    settoones::Vector{Vector{Symbol}}
    settozeros::Vector{Vector{Symbol}}
    setdepending::Dict{Symbol,Vector{Vector{Symbol}}}
end

function parse_traits_mod_args(args)
    remove_line_number_node!(args)
    @assert args.head == :block
    result = [parse_individual_trait_mod_arg(i) for i in args.args]
    Ones = [i[1] for i in result if i[2] == 1]
    Zeros =  [i[1] for i in result if i[2] == 0]
    Depending = Dict{Symbol,Vector{Vector{Symbol}}}()
    for x in result
        i,j = x
        if j isa Symbol
            if haskey(Depending, j)
                push!(Depending[j],i)
            else
                Depending[j] = [i]
            end
        end
    end
    return traitsArguments(Ones,Zeros,Depending)
end

function walk_trait_pool_descriptor(walk::Vector{Symbol}, trait_pool_descriptor::PoolDescriptor)
    #this is a concrete function.
    for i in walk
        trait_pool_descriptor = trait_pool_descriptor.args[i]
    end
    return trait_pool_descriptor
end



macro settraits(variable,args)
    trait_pool_descriptor = get_trait_pool_descriptor(variable)
    parsed_args = parse_traits_mod_args(args)
    #println(parsed_args)
    
    #println(trait_pool_descriptor)
end

macro addtraits(variable,args)
    trait_pool_descriptor = get_trait_pool_descriptor(variable)
    parsed_args = parse_traits_mod_args(args)
    static_bits = [walk_trait_pool_descriptor(i,trait_pool_descriptor) for i in parsed_args.settoones]
    bits = reduce(Base.:|, UInt64(1).<<(static_bits.-1))
    answer = :(getvalue($variable)|$bits)
    for (dependent_var,dependent_value) in parsed_args.setdepending
        dynamic_bits = [walk_trait_pool_descriptor(i,trait_pool_descriptor) for i in parsed_args.settoones]
        bits = reduce(Base.:|, UInt64(1).<<(dynamic_bits.-1))
        answer = :($answer | ((getvalue($dependent_var))&($bits)))
    end
    return esc(:($variable= setvalue($variable,$answer)))
end

macro removetraits(variable, args)
    trait_pool_descriptor = get_trait_pool_descriptor(variable)
    parsed_args = parse_traits_mod_args(args)
    static_bits = [walk_trait_pool_descriptor(i,trait_pool_descriptor) for i in parsed_args.settoones]
    bits = reduce(Base.:|, UInt64(1).<<(static_bits.-1))
    answer = :(getvalue($variable)&~($bits))
    for (dependent_var,dependent_value) in parsed_args.setdepending
        dynamic_bits = [walk_trait_pool_descriptor(i,trait_pool_descriptor) for i in parsed_args.settoones]
        bits = reduce(Base.:|, UInt64(1).<<(dynamic_bits.-1))
        answer = :($answer & ~((getvalue($dependent_var))&($bits)))
    end
    return esc(:($variable= setvalue($variable,$answer)))
end

macro fliptraits(variable,args)
    trait_pool_descriptor = get_trait_pool_descriptor(variable)
    parsed_args = parse_traits_mod_args(args)
    static_bits = [walk_trait_pool_descriptor(i,trait_pool_descriptor) for i in parsed_args.settoones]
    println(static_bits)
    bits = reduce(Base.:|, UInt64(1).<<(static_bits.-1))
    answer = :(getvalue($variable)⊻$bits)
    for (dependent_var,dependent_value) in parsed_args.setdepending
        dynamic_bits = [walk_trait_pool_descriptor(i,trait_pool_descriptor) for i in parsed_args.settoones]
        bits = reduce(Base.:|, UInt64(1).<<(dynamic_bits.-1))
        answer = :($answer | ((getvalue($dependent_var))⊻($bits)))
    end
    return esc(:($variable= setvalue($variable,$answer)))
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



@make_traitpool "ABCDEF" Pokemon
@make_traitpool "ABCDEF" X
@settraits Pokemon begin
    @trait electro 
    @trait roles.attacker 1
    @trait roles.attacker.dive.fun X
    @trait roles.attacker.wing X
end

@addtraits Pokemon begin
    @trait meta.earlygame
    @trait electro
    @trait laser X
end

println(@macroexpand @addtraits Pokemon begin
    @trait meta.earlygame
    @trait electro
    @trait laser X
end)

println(@macroexpand @removetraits Pokemon begin
    @trait meta.earlygame
    @trait electro
    @trait laser X
end)
println(@macroexpand @fliptraits Pokemon begin
    @trait meta.earlygame
    @trait electro
    @trait laser X
end)
#println("Finish.")

