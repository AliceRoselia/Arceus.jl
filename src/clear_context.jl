macro clear_context()
    module_name = @__MODULE__
    eval(:(($module_name).TRAIT_POOL_TYPES =  Dict{Symbol, Type{<:TraitPool}}()))
    eval(:(($module_name).SUB_POOL_TYPES =  Dict{Symbol, Type{<:SubPool}}()))
end