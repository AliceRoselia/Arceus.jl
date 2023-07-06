struct magic_constructor{F<:Function}
    mask::UInt64
    magic::UInt64
    shift::Int64
    func::F

end

struct pre_magic_constructor{F<:Function}
    mask::UInt64
    func::F
end

#This MUST be a compile_time constant.

abstract type Lookup end

#LOOK_UP_NAMES = Dict{String,Type{<:Lookup}}()
LOOK_UP_TYPES = Dict{Symbol,magic_constructor}()


function replace_property!(a::Expr, i, j)
    if (a.head == i)
        a.head = j
    end
    for arg in eachindex(a.args)
        if a.args[arg]  isa Symbol
            if (a.args[arg] == i)
                
                a.args[arg] = j
            end
        elseif a.args[arg]  isa Expr
            replace_property!(a.args[arg] ,i,j)
        end
    end
end

function add_mask_from_rule!(rule,arr)
    return
end


function add_mask_from_rule!(rule::Expr,arr)
    if rule.head == :macrocall && (rule.args[1] ==Symbol("@hastrait") || rule.args[1] == Symbol("usetrait"))
        #println(rule|>dump)
        push!(arr,rule.args[2])
    end
    for i in rule.args
        add_mask_from_rule!(i,arr)
    end
end

function get_mask_from_rule(rule,parent_pool,var)
    arr::Vector{Any} = []
    remove_line_number_node!(rule)
    add_mask_from_rule!(rule,arr)
    arr2::Vector{Vector{Symbol}} = [parse_walk_chain(expression) for expression in arr]
    #println(arr2)
    module_name = @__MODULE__
    trait_pool_descriptor = module_name.TRAIT_POOL_DESCRIPTORS[module_name.TRAIT_POOL_NAMES[parent_pool]]
    ans = UInt64(0)
    for i in arr2
        if i[1] == var
            traitnum = walk_trait_pool_descriptor(i[2:end],trait_pool_descriptor)
            trait_bit = UInt64(1)<<(traitnum-1)
            ans |= trait_bit
        end
    end
    #println(rule|>dump)
    #error("Working in progress.")
    return ans
end


macro lookup(var, parent_pool, rule)
    f1 = gensym()
    f2 = gensym()
    x = gensym()
    mask = get_mask_from_rule(deepcopy(rule),parent_pool,var) #TO BE COMPLETED.
    magic = gensym()
    shift = gensym()
    #Do something with this.
    parent_pool_type = get_trait_pool_type(parent_pool)

    get_f2 = :($f2 = $x -> $f1($parent_pool_type($x)))
    get_mask_and_magic = :(($magic,$shift) = find_magic_bitboard($mask,$f2))
    magic_constructor_instantiate = :(magic_constructor($mask,$magic,$shift,$f2))
    #println(magic_constructor_instantiate)
    return esc(:($f1 = @get_lookup_function $var $parent_pool $rule;
        $get_f2;
        $get_mask_and_magic;
        $magic_constructor_instantiate
    ))
end


macro get_lookup_function(var, parent_pool, rule)
    #Create a new struct type. 
    #Lookup is a string...
    x = gensym()
    replace_property!(rule,var,x)
    #println(var)
    rule_function = :($x->eval($rule))
    ans = :(@register_traitpool $parent_pool $x; $rule_function)
    #println(rule_function)
    return esc(ans)
end



function get_lookup_constants(m::magic_constructor)
    
    #This function returns short, simple constants to be used as literals in macro.
    return_type = Base.return_types(f,(UInt64))
    
    return (1<<(64-m.shift), m.mask,m.magic,m.shift, m.func, return_type)
end

macro make_lookup(lookup, variable)
    var_quot = Meta.quot(variable)
    module_name = @__MODULE__
    eval(:(($module_name).LOOK_UP_TYPES[$var_quot] = $lookup))
    error("Working in progress.")
    #TODO... return something...
end

macro register_lookup(lookup,variable)
    var_quot = Meta.quot(variable)
    module_name = @__MODULE__
    eval(:(($module_name).LOOK_UP_TYPES[$var_quot] = $lookup))
    return
end








macro get_lookup_value(variable, traitpool, Global = true)
    if Global 
        return esc(:(global $variable ;$variable[begin + (@get_lookup_index variable traitpool)]))
    else
        return esc(:($variable[@get_lookup_index variable traitpool]))
    end
end

macro get_lookup_index(variable, traitpool)
    #Index is 0-based here.
    error("Working in progress.")
    return :(0)
end

function parse_mask_join_individual_arg(mask_trait::Expr)
    @assert mask_trait.head == :macrocall
    @assert mask_trait.args[1] == Symbol("@trait")
    return mask_trait.args[2]
end

function parse_mask_join_args(mask)
    @assert mask.head == :block
    return [parse_mask_join_individual_arg(x) for x in  mask.args]
end
macro getmask(pool, traits)
    remove_line_number_node!(traits)
    #println(parse_mask_join_args(traits))
    mask_join_args = parse_mask_join_args(traits)
    mask_join_args = [parse_walk_chain(i) for i in mask_join_args]
    #println(mask_join_args)
    module_name = @__MODULE__
    trait_pool_type = get_trait_pool_type(pool)
    trait_pool_descriptor = module_name.TRAIT_POOL_DESCRIPTORS[trait_pool_type]
    arr = [walk_trait_pool_descriptor(x,trait_pool_descriptor) for x in mask_join_args]
    #println(arr)
    ans = reduce(Base.:|, UInt64(1).<<(arr.-1);init=0)
    return :($ans)
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

@join_subpools Pokemon begin
    @subpool biometraits2
    @subpool metatraits
end

mask = @getmask "ABCDEF" begin 
    @trait electro
    @trait flame 
    @trait reserve1.biome_preference.beach_preference
end

#println(mask)





f1 = @lookup k "ABCDEF" begin
    out = 1
    if @hastrait k.electro
        out *= 2
    end
    if @hastrait k.flame
        out *= 1.5 
    end
    if @hastrait k.meta.earlygame
        out *= 1.2
    end
    return out
end
#Make_lookup is global scope only.
@register_lookup f1 x_arr
#=
println((@macroexpand @lookup k "ABCDEF" begin
    out = 1
    if @hastrait k.electro
        out *= 2
    end
    if @hastrait k.flame
        out *= 1.5 
    end
    if @hastrait k.meta.earlygame
        out *= 1.2
    end
    return out
end))
=#
println(f1.func(getvalue(Pokemon)))
#println(f1(Pokemon))

arr = Vector{Function}(undef,10)

println("finish")
#=
for i in 1:10
    arr[i] = @lookup x "ABCDEF" begin
        
        out = i
        if @hastrait x.electro
            out *= 2+i
        end
        if @hastrait x.flame
            out *= 1.5 
        end
        if @hastrait x.meta.earlygame
            out *= 1.2
        end
        if @hastrait x.meta.lategame
            out += i
        end
        return out
    end

end
=#