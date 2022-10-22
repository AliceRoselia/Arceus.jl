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