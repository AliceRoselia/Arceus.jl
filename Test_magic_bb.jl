mask = UInt64(0x0000302510007000)
print_magic_bb(mask)


function test1_f(x::UInt64)
    mask = UInt64(0x0000302510007000)
    x = x&mask
    if (x%7 == 5)
        return DONTCARE()
    else 
        return x%11
    end
end

magic, shift = find_magic_bitboard(mask, test1_f, UInt64)

arr = fill_magic_bitboard(mask, test1_f, UInt64, guess, shift)
#This assumes a successful load.

@testset "A"
for i in maskedBitsIterator(mask)
    @test test1_f(i) == use_magic_bitboard(arr, mask, magic, shift, i)
end
