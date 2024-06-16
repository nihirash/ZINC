;; EBIOS - Emulation BIOS. BIOS emulation layer for ZINC
;; (c) 2024 Aleksandr Sharikhin
;;
;; All rights are reserved


bios_const:
    LOCALSP
    call.lil ZINC_TERMST
    RESTORESP
    ret

bios_in:
    LOCALSP
    call.lil ZINC_TERMIN
    RESTORESP
    ret

bios_out:
    LOCALSP
    call.lil ZINC_TERMOUT
    RESTORESP
    ret