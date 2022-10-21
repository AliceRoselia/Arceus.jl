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