
struct magicBitboard{resultType}
    ans::Vector{resultType}
    mask::UInt64
    magic::UInt64
    shift::Int8
end

struct maskedBitsIterator
    mask::UInt64
    reverse_mask::UInt64
    maskedBitsIterator(mask::UInt64) = new(mask,~mask)
    maskedBitsIterator(mask) = maskedBitsIterator(UInt64(mask))
end
Base.iterate(::maskedBitsIterator) = UInt64(0),UInt64(0)

function Base.iterate(X::maskedBitsIterator, state)
    ans = X.mask&((state|X.reverse_mask)+1)

    return ifelse(ans==0, nothing, (ans,ans))
end


function use_magic_bitboard(X::magicBitboard, query::UInt64)
    return use_magic_bitboard(X.ans, mask, magic, shift, query)
end

function use_magic_bitboard(arr::AbstractVector, mask::UInt64, magic::UInt64, shift::Integer, query::UInt64)
    return @inbounds arr[get_lookup_index(mask, magic, shift, query)]
end

function get_lookup_index(mask::UInt64, magic::UInt64, shift::Integer, query::UInt64)
    return (((query&mask)*magic)>>shift)+1
end

struct DONTCARE end;



#=

Assumption: if it exists in mask, then it is used in at least one spot. 
That is, there is some point where masking that bit is required.

Only a subset needs to be searched.
The number which overflows the last masked bit does not need to be searched. Pruned.
Imagined
00000...00000* magic = 00000...
Now, for any number not equal 000...000
There must be some bits in the magic bit corresponding. 

With only 1 bit, and each with different number, must be different...
however... yeah.

TORD suggests a densely populated bit...

For each r, it loops every 2^64/gcd(2^64, r)

Its proof is simple. Let's say 10 and 4.
It will go through 10/gcd(10,4) = 5 and then loop around.

lcm(r1, r2, r3, ...) may reduce the size down.

gcd(X::UInt64, big_interval) = X&-X
proof: Last bit.



U64 snoob (U64 x) {
   U64 smallest, ripple, ones;
   smallest = x & -x;
   ripple = x + smallest;
   ones = x ^ ripple;
   ones = (ones >> 2) / smallest;
   return ripple | ones;
}

1111100000000011100
1111100000000100000
ripple add.
0000000000000111100
ones, removing higher bits.
0000000000000000011
two ones gone.
1111100000000100011
Now, the rippled one and the bit before the ripple unset... then shifted back to the beginning.0.
The rippled one definitely the last one.
=#


"
returns the last number which needs to be checked.
This loops from zero to that number. zero magic number, however, yields trivial result mapping all to the same value, and thus not need to be checked.
"
function magic_bitboard_range(mask)
    #The last bit represents its 
    Big_interval=Int128(2)^64
    
    return UInt64(div(Big_interval,(mask&-mask))-1)
end



"""
answer_table: An iterable of occupancy and answers.
"""
function verify_magic_bitboard(answer_table,magic::UInt64, shift, return_type::Type)
    A = Vector{Union{return_type, DONTCARE}}(undef, 1<<(64-shift))
    A.= DONTCARE
    for (traits, ans) in answer_table
        index = ((traits*magic)>>shift)+1
        if (A[index] === DONTCARE)
            A[index] = ans
        elseif (A[index] != ans)
            return false
        end
    end
    return true
end
"""
The mask suggests all the combinations possible.
f takes input as the bit representation of traits. This function should be constructed with helps of macros.
f should return Union{return_type, DONTCARE}
The DONTCARE suggests that the magic could do whatever it wants.

"""
function get_guess()
    error("working in progress.")
end

function get_new_guess(guess)
    error("working in progress.")
end

function find_magic_bitboard(mask::UInt64, f::Function, return_type::Type = Any, shift_minimum::Integer = 32, guess_limits::Integer=1000000)
    answer_table = Dict{UInt64, return_type}()
    #We get a hash table but not a perfect one so we need to do it again.
    for i in maskedBitsIterator(mask)
        Temp::Union{return_type, DONTCARE} = f(i)
        if Temp !== DONTCARE
            answer_table[i] = Temp
        end
    end
    answer_table = collect(answer_table)
    #Now, we need to find the perfect hash that solves this answer table.
    guess = get_guess() #Can change if needed.
    initial_shift = shift = get_shift(mask)
    limit = guess_limits
    while !(verify_magic_bitboard(answer_table, guess, shift, return_type))
        guess = get_new_guess(guess)
        limit -= 1
        if (limit <= 0)
            shift -= 1
            if (shift < shift_minimum)
                error("Cannot find magic bitboard with sufficiently small size (indicated by shift_minimum).")
            end
            limit = guess_limits
        end
    end
    answer_guess = guess
    answer_shift = shift
    if (shift == initial_shift)
        trying_to_shrink = true
        while trying_to_shrink
            answer_guess = guess
            answer_shift = shift
            shift += 1
            limit = guess_limits
            if (shift >= 64)
                break
            end
            limit = guess_limits
            while !(verify_magic_bitboard(answer_table, guess, shift, return_type))
                guess = get_new_guess(guess)
                limit -= 1
                if (limit <= 0)
                    trying_to_shrink = false
                    break
                end
            end
        end
    end

    return answer_guess, answer_shift
    #You can construct later.
end

function print_magic_bb(A::UInt64)
    x = bitstring(A)
    for i in 1:8:64
        println(x[i:i+7])
    end
end

