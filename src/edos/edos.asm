;; EDOS - Emulation DOS. BDOS emulation layer for ZINC
;; (c) 2024 Aleksandr Sharikhin
;;
;; All rights are reserved

    include "../config.asm"
    ASSUME ADL=1
    org EDOS_ORG
    ASSUME ADL=0
 
    include "core.asm"