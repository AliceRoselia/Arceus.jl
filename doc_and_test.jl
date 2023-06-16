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
#Subpool also must be defined at compile time.
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

@register_subpool "Biome" biometraits3

@join_subpools Pokemon begin
    @subpool biometraits2
    @subpool metatraits
end