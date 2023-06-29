#This is a testable documentation showing all the features.


#Traitpool must be defined at compile time.
@traitpool "ABCDEF" begin
    @trait electro
    @trait flame #Defining trait without bits.
    @trait laser 2 #Defining trait with a specified bit (from the right or least significant.)
    @subpool roles begin
        @trait attacker
        @trait support
        
    end
    @subpool meta 16-32 begin #Subpool can be defined with a specified number of bits, but for a concrete subpool, the number of bits can be defined.
        @trait earlygame
        @trait midgame
        @trait lategame
    end
    @abstract_subpool reserve1 33-48 #Defining start and finish bits.
    @abstract_subpool reserve2 8 #Defining the size, but not the sub_trait.
end
#This will register the variable at compile time and construct a trait pool at runtime.
@make_traitpool "ABCDEF" Pokemon begin
    @trait electro #Creating trait pool with the following traits.
    @trait flame
end
#Subpool also must be defined in the global scope.
@subpool "Biome" "ABCDEF".reserve1.biome_preference begin
    @trait beach_preference
    @trait ice_preference
    @trait volcanic_preference
end
#Defining concrete subpool. 
@subpool "Meta" "ABCDEF".meta

@make_subpool "Biome" biometraits Pokemon
@make_subpool "Meta" metatraits Pokemon
@make_subpool "Biome" biometraits2 begin
    @trait beach_preference 1
    @trait ice_preference 0
    @trait volcanic_preference
end
#This "registers" subpool.
#Usage...
function x(biometraits3::get_trait_pool_type("Biome"))
    @register_subpool "Biome" biometraits3 #Since this is a subpool.
    #Use @register_traitpool for a non-subpool trait pool.
end
#Or you can maybe use generated function to manipulate the type yourself (see the register_traitpool macro) but that comes with its own issue (world age issue).
#=
macro register_traitpool(traitpool, variable)
    var_quot = Meta.quot(variable)
    traitpool_struct = TRAIT_POOL_NAMES[traitpool] # Remove this line if you're accepting trait pool type already.
    module_name = @__MODULE__
    eval(:(($module_name).TRAIT_POOL_TYPES[$var_quot] = $traitpool_struct))
    return
end

This does make it a bit difficult to use generics. Should be fine because each trait pool has different traits and could be incompatible anyway.

=#


#This joins the subpools to their parent traitpool (Presume parent, otherwise they write whatever bits they happen to occupy).
#This syntax is used for the sake of consistent syntax across the entire package.
@join_subpools Pokemon begin
    @subpool biometraits2
    @subpool metatraits
end