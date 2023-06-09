macro clear_context()
    module_name = @__MODULE__
    eval(:(($module_name).TRAIT_POOL_TYPES =  Dict{Symbol, Type{<:TraitPool}}()))
end