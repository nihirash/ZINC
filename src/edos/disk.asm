;; EDOS - Emulation DOS. BDOS emulation layer for ZINC
;; (c) 2024 Aleksandr Sharikhin
;;
;; All rights are reserved

get_drives:
    ld hl,1
    ret

get_drive:
    xor a
    ret

set_dma:
    ld (dma_ptr),de
    ret

get_dpb:
    ld hl, dpb
    ret