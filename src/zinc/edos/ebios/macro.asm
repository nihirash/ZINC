;; EBIOS - Emulation BIOS. BIOS emulation layer for ZINC
;; (c) 2024 Aleksandr Sharikhin
;;
;; All rights are reserved

    macro LOCALSP
    di
    ld (user_sp_ptr), sp
    ld sp, bios_stack
    push ix
    push iy
    ei
    endmacro

    macro RESTORESP
    di
    pop iy
    pop ix
    ld sp, (user_sp_ptr)
    ei
    endmacro
