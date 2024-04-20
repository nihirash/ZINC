;; ZINC is Not CP/M
;;
;; CP/M compatibility layer for Agon's MOS
;; (c) 2024 Aleksandr Sharikhin
;;
;; All rights are reserved

;; ----------------------------------------------------------------------------
;; This configuration file will affect executable and EDOS parts both
;;
;; Don't modify this values if you don't really know what you want get.
;;
;; All this values affects all system
;; ----------------------------------------------------------------------------


;; Replace ZINC_BASE to $40000 for using it from `/bin` path or as standalone application
;; Or keep it as usual moslet - emulator is really tiny and works fine here
ZINC_BASE:  equ $B0000
ZINC_EXIT:  equ ZINC_BASE + 4

;; By changing this value you can change used memory page for CP/M application
EDOS_BASE:  equ $A0000
;; Origin address for EDOS(BDOS equivalent in ZINC)
EDOS_ORG:   equ EDOS_BASE + $f000
;; TPA area starts here
EDOS_TPA:   equ EDOS_BASE + $100

;; CP/M 2.2 is $22
;; Personal CP/M-80 is $28
;; Let be ZINC is $29. 
;; Cause compatibility target will be 2.x line but it's totally new version
DOSVER:     equ $29