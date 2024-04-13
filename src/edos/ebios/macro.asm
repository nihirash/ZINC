    macro LOCALSP
    di
    ld (user_sp_ptr), sp
    ld sp, bios_stack
    ei
    endmacro

    macro RESTORESP
    di
    ld sp, (user_sp_ptr)
    ei
    endmacro
