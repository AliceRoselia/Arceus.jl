
struct magicBitboard{resultType}
    ans::Vector{resultType}
    mask::UInt64
    magic::UInt64
    shift::Int8
end

function use_magic_bitboard(X::magicBitboard, query::UInt64)
    return use_magic_bitboard(X.ans, mask, magic, shift, query)
end

function use_magic_bitboard(arr::AbstractVector, mask::UInt64, magic::UInt64, shift::Integer, query::UInt64)
    return @inbounds arr[get_lookup_index(mask, magic, shift, query)]
end

function get_lookup_index(mask::UInt64, magic::UInt64, shift::Integer, query::UInt64)
    return ((query&mask)*magic)>>shift
end
