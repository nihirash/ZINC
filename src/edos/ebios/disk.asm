;; EBIOS - Emulation BIOS. BIOS emulation layer for ZINC
;; (c) 2024 Aleksandr Sharikhin
;;
;; All rights are reserved

bios_seldsk:
    ld hl, dph
    ret

bios_dma:
    ld (dma_ptr), bc
    ret

dph:
    dw 0, 0, 0, 0, dir, dpb, 0, 0

;; Almost random data - no direct disk operations will be allowed anyway
;; I've used from Agon's CP/M 2.2
dpb:
    dw	64	    ;sectors per track
    db	6		;block shift factor
    db	63		;block mask
    db	3   	;null mask
    dw	1023	;disk size-1
    dw	2047 	;directory max
    db	$ff		;alloc 0
    db	0		;alloc 1
    dw	0	    ;check size - don't care about it - SD card isn't removable
    dw	0	    ;track offset


dir:
    ds 128