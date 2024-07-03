; CPSSER.ASM
;       KERMIT - (Celtic for "FREE")
;
;       This is the CP/M-80 implementation of the Columbia University
;       KERMIT file transfer protocol.
;
;       Version 4.0
;
;       Copyright June 1981,1982,1983,1984
;       Columbia University
;
; Originally written by Bill Catchings of the Columbia University Center for
; Computing Activities, 612 W. 115th St., New York, NY 10025.
;
; Contributions by Frank da Cruz, Daphne Tzoar, Bernie Eiben,
; Bruce Tanner, Nick Bush, Greg Small, Kimmo Laaksonen, Jeff Damens, and many
; others. 
;
;       This file contains the (system-independent) routines that implement
;       the SERVER part of the KERMIT protocol.
;
; revision history:
;
;
; edit 1: September, 1987.  Created CPSSER.ASM from bits from the two CPSPK?
;	files.  
;	The code herein is to allow remote systems to communicate to 
;	this Kermit running in SERVER mode.  Note that not every server 
;	command will be supported, mind...
;
server:	db	'CPSSER.ASM (1)  8-SEP-87$'	; name, edit number, date



; Little code to allow some expansion of code without changing
;  every futher address, only up to the end of this file.
;   TO BE REMOVED FOR RELEASE!

;	org ($+100h) AND 0FF00H


IF lasm
	LINK	CPSTT
ENDIF;lasm
