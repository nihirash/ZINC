IF NOT lasm
.printx * CPXCOM.ASM *
ENDIF	; NOT lasm
;       KERMIT - (Celtic for "FREE")
;
;       This is the CP/M-80 implementation of the Columbia University
;       KERMIT file transfer protocol.
;
;       Version 4.0
;
;       Copyright June 1981,1982,1983,1984,1985
;       Columbia University
;
; Originally written by Bill Catchings of the Columbia University Center for
; Computing Activities, 612 W. 115th St., New York, NY 10025.
;
; Contributions by Frank da Cruz, Daphne Tzoar, Bernie Eiben,
; Bruce Tanner, Nick Bush, Greg Small, Kimmo Laaksonen, Jeff Damens, and many
; others.
;
;       This file contains part common code required for most if not all
;	systems.  Specifiacally, SYSINIT, INIADR, MOVER, and DELAY to name
;	the most important ones.
;
; revision history:
;
; edit 1, 21st July 1987 by OBSchou.  Regretably, I have had to include
;	some system dependent IFs, mainly for CRT, TORCH and OSI.  Inclusion
;	here means simpler family files later on. (Regrettably, the delay
;	loop for APMMDM differs too.)
;
; Set the fuzzy timeout value.  Range is 1 (VERY short) through 0ffffH to zero
; (maximum).  The actual duration is a function of the loop length and the
; processor speed.  For now, we'll make it zero for everybody, but feel free
; to change it for your system.
; [OBS] make it a little less than max, say 1000H.  More useful.
fuzval  EQU     1000H

;
;       System-dependent initialization
;       Called once at program start.
sysinit:
;
; [13]  Had to move this call to here, as the prtstr routine needs this
; before the config message is sent out.  It has only been moved.
;
	call	iniadr	;Initialize the BIOS addresses
	mvi	c,gtiob	;Get current I/O byte
	call	bdos	;From CP/M
	sta	coniob	;Remember where console is
	mvi	c,getvnm	; get the BDOS version number (e.g. 22H, 31H)
	call	bdos
	mov	a,l
	sta	bdosvr		; and store it away for future reference
	lxi	d,cfgmsg	; "configured for "
	call	prtstr
	lxi	d,sysver	; get configuration we're configured for
	call	prtstr		; print it.
;
;       If we're set up to do special terminal handling, say what kind
;       of terminal we expect... (unless it's the generic 'crt')
IF termin
	lxi	d,witmsg	; " with "
	call	prtstr
	lxi	d,ttytyp	; terminal type
	call	prtstr
ENDIF;termin
	call	prcrlf		; print CR/LF
;
; now, to work...
;
; locate large buffer for multi-sector I/O
; What we want to do here is find the ccp.  Space between ovlend and the ccp
; is available for buffering, except we don't want to use more than maxsec
; buffers (if we use too many, the remote end could time out while we're
; writing to disk).  maxsec is system-dependent, but for now we'll just
; use 8Kbytes.  If you get retransmissions and other protocol errors after
; transferring the first maxsec sectors, lower maxsec.

maxsec	EQU	(8*1024)/bufsiz	; 8K / number of bytes per sector

	lxi	h,ovlend	; get start of buffer
	shld	bufadr		; store in linkage section
	mvi	a,maxsec	; get size of buffer, in sectors
	sta	bufsec		; store that, too.

	call	sysxin		; call system specific init code

	ret			; return from system-dependent routine

bdosvr:	ds	1		; space to save the BDOS version number
IF NOT iobyt
coniob:	ds	1		; space to save copy of IO byte
ENDIF	;NOT iobyt
;
;       This one is hopefully the last "improvement" in view of GENERIC
;Kermit. It uses for Character-I/O the BIOS-routines ( instead of the
;"normal" BDOS routines. What does it give us (hopefully) : More speed,
;higher chance of success ( I/O byte implemented in BIOS [if at all]),
;but no "extra" device handling - that's done by BDOS.
;
;       How do we "get" the call-adresses?  Location 0 has a JMP Warm-Boot
;in CP/M which points into the second location of the BIOS JMP-Vector.  The
;next three locations of the JMP-Vector point to the CONSTAT,CONIN,CONOUT
;BIOS-routines.  CONOUT wants the character in C.
;
;- Bernie Eiben

iniadr:	lhld	1		;get BIOS Warmstart-address
	lxi	d,3		;next adress is CONSTAT in BIOS
	dad	d
	shld	bconst+1	;stuff it into the call-instruction
	lxi	d,3		;next adress is CONIN in BIOS
	dad	d
	shld	bconin+1	;
	lxi	d,3		;next adress is CONOUT in BIOS
	dad	d
	shld	bcnout+1
	lxi	d,3		;next address is LIST in BIOS
	dad	d
	shld	blsout+1
	lxi	d,10*3		; get printer status routine
	dad	d
	shld	bprtst
	ret			;And return

bconst:	jmp	$-$		;Call BIOS directly (filled in by iniadr)

bconin:	jmp	$-$		;Call BIOS directly (filled in by iniadr)

bcnout:	jmp	$-$		;Call BIOS directly (filled in by iniadr)

blsout:	jmp	$-$		; ....

bprtst:	jmp	$-$		; Call BIOS directly for printer status

IF NOT apmmdm	; Shame about this, but the Apple needs a different delay
;
;[cjc]  Delay routine.  Called with time (hundredths of seconds) in A.
;       The inner loop delays 1001 T-states, assuming no wait states are
;       inserted; this is repeated CPUSPD times, for a total delay of just
;       over 0.01 second. (CPUSPD should be set to the system clock rate,
;       in units of 100KHz: for an unmodified Kaypro II, that's 25 for
;       2.5 MHz.  Some enterprising soul could determine whether or not the
;       Kaypro actually inserts a wait state on instruction fetch (a common
;       practice); if so, the magic number at delay2 needs to be decreased.
;       (We also neglect to consider time spent at interrupt level).
;
;       called by: sendbr
;       destroys BC

delay:	mvi	c,cpuspd	; Number of times to wait 1000 T-states to
				;  make .01 second delay
delay2:	mvi	b,70		; Number of times to execute inner loop to
				;  make 1000 T-state delay
delay3:	dcr	b		; 4 T-states (* 70 * cpuspd)
	jnz	delay3		; 10 T-states (* 70 * cpuspd)
	dcr	c		; 4 T-states (* cpuspd)
	jnz	delay2		; 10 T-states (* cpuspd)
				; total delay: ((14 * 70) + 14) * cpuspd
				;  = 1001 * cpuspd
	dcr	a		; 4 T-states
	jnz	delay		; 10 T-states
	ret			; grand total: ((1001 * cpuspd) + 14) * a
ENDIF	; NOT apmmdm
;
;
;       Set up screen display for file transfer
;       called with kermit version in DE
;
sysscr: push    d               ; save version for a bit
        lxi     d,outlin        ; clear screen, position cursor
        call    prtstr          ; do it
        pop     d               ; get Kermit's version
IF NOT (osi OR crt)             ; got cursor control?
        call    prtstr          ; print it
        mvi     e,'['           ; open bracket
        call    outcon          ; print it (close bracket is in outln2)
        lxi     d,sysver        ; get name and version of system module
        call    prtstr
        lxi     d,outln2        ; yes, print field names
        call    prtstr
        lda     dbgflg          ; is debugging enabled?
        ora     a
        rz                      ; finished if no debugging
        lxi     d,outln3        ; set up debugging fields
        call    prtstr
ENDIF;NOT (osi OR crt)
        ret
;
;       Calculate free space for current drive
;       returns value in HL
sysspc:
        lda     bdosvr          ;cpm3's alloc vect may be in another bank
        cpi     30H             ;cpm3 or later?
        jm      cp2spc          ;no: use cp/m 2 algorithm
        lda     fcb             ;If no drive, get
        ora     a               ; logged in drive
        jz      dir180
        dcr     a               ;FCB drive A=1 normalize to be A=0
        jmp     dir18a

dir180: mvi     c,rddrv
        call    bdos
dir18a: mov     e,a             ;drive in e
        mvi     c,getfs         ;get free space BDOS funct
        call    bdos            ;returns free recs (3 bytes in buff..buff+2)
        mvi     b,3             ;conv recs to K by 3 bit shift
dir18b: xra     a               ;clear carry
        mvi     c,3             ;for 3 bytes
        lxi     h,buff+3        ;point to addr + 1
dir18c: dcx     h               ;point to less sig. byte
        mov     a,m             ;get byte
        rar                     ;carry -> A -> carry
        mov     m,a             ;put back byte
        dcr     c               ;for all bytes (carry not mod)
        jnz     dir18c
        dcr     b               ;shift 1 bit 3 times
        jnz     dir18b
        mov     e,m             ;get least sig byte
        inx     h
        mov     d,m             ;get most sig byte
        xchg                    ;get K free in HL
        ret

; the rest are CP/M 2.2 systems, so use the alloc vector
cp2spc: mvi     c,getalv        ;Address of CP/M Allocation Vector
        call    bdos
        xchg                    ;Get its length
        lhld    bmax
        inx     h
        lxi     b,0             ;Initialize Block count to zero
dir19:  push    d               ;Save allocation address
        ldax    d
        mvi     e,8             ;set to process 8 blocks
dir20:  ral                     ;Test bit
        jc      dir20a
        inx     b
dir20a: mov     d,a             ;Save bits
        dcx     h
        mov     a,l
        ora     h
        jz      dir21           ;Quit if out of blocks
        mov     a,d             ;Restore bits
        dcr     e               ;count down 8 bits
        jnz     dir20           ;do another bit
        pop     d               ;Bump to next count of Allocation Vector
        inx     d
        jmp     dir19           ;process it

dir21:  pop     d               ;Clear Allocation vector from stack
        mov     l,c             ;Copy block to 'HL'
        mov     h,b
        lda     bshiftf         ;Get Block Shift Factor
        sui     3               ;Convert from records to thousands
        rz                      ;Skip shifts if 1K blocks
dir22:  dad     h               ;Multiply blocks by 'K per Block'
        dcr     a
        jnz     dir22
        ret

;      +----|----|----|----|----|----|----|...
;    1 |
;    2 |                Kermit-80 v4.0 [system]
;    3 |
;    4 |Number of packets: ____
;    5 |Number of retries: ____
;    6 |File name: ____________
;    7 |<error>...
;    8 |<status>...
;    9 |RPack: ___(if debugging)...
;   10 |
;   11 |SPack: ___(if debugging)...
;   12 |
;   13 |Kermit-80  A:>  (when finished)
;
; For the PX-8, the display looks like:
;           5    10   15   20   25   30   35   40   45   50   55
;      +----|----|----|----|----|----|----|----|----|----|----|----|----
;    1 |Kermit-80 v4.05 [Epson PX-8]            Number of retries: ____
;    2 |Number of packets: ____                 File name: ________.___
;    3 |<error>...
;    4 |<status>...
;    5 |RPack: ___ (if debugging)...
;    6 |
;    7 |SPack: ___ (if debugging)...
;    8 |
;    9 |Kermit-80 A:> (when finished)
;

IF NOT px8 ; [29]
nppos   EQU     4*100h+20
rtpos   EQU     5*100h+20
fnpos   EQU     6*100h+12
errlin  EQU     7
stlin   EQU     8
rplin   EQU     9
splin   EQU     11
prplin  EQU     13
ENDIF ; NOT px8

IF px8
nppos   EQU     2*100h+20
rtpos   EQU     1*100h+59
fnpos   EQU     2*100h+51
errlin  EQU     3
stlin   EQU     4
rplin   EQU     5
splin   EQU     7
prplin  EQU     9
ENDIF ; px8 [29]


IF NOT (osi OR crt );[26]
scrnp:  lxi     b,nppos
        jmp     csrpos

scrnrt: lxi     b,rtpos
        jmp     csrpos

scrfln: lxi     b,fnpos
        call    csrpos
clreol:
        lxi     d,tk
        jmp     prtstr

screrr: lxi     b,errlin*100H+1
        call    csrpos
        jmp     clreol

scrst:  lxi     b,stlin*100H+1
        call    csrpos
        jmp     clreol

rppos:  lxi     b,rplin*100H+8
        call    csrpos
        jmp     clreol

sppos:  lxi     b,splin*100H+8
        call    csrpos
        jmp     clreol

; [29] Modify scrend to make the cursor line conditional on use of debugging
; This means that in most cases the entire file transfer will fit on PX-8 lcd
scrend: lda     dbgflg
        ora     a
        jz      scr1nd
        lxi     b,prplin*100H+1 ; debugging in use [29]
        jmp     scr2nd
scr1nd: lxi     b,rplin*100H+1  ; no debugging
scr2nd: call    csrpos
clreos: lxi     d,tj
        jmp     prtstr
; [29]  and nop out the rest for now...
;
;scrend:        lxi     b,prplin*100H+1
;       call    csrpos
;clreos:        lxi     d,tj
;       jmp     prtstr
ENDIF;NOT (osi OR crt ) [26]


IF osi OR crt   ; no cursor control
scrnp:  mvi     e,' '
        jmp     outcon

scrnrt: mvi     e,' '
        call    outcon
        mvi     e,'%'
        jmp     outcon

scrfln:
screrr:
scrst:
scrend: jmp     prcrlf          ;Print CR/LF    [Toad Hall]

rppos:  lxi     d,prpack
        jmp     prtstr

sppos:  lxi     d,pspack
        jmp     prtstr
ENDIF;osi OR crt

; Some frequently-used routines (duplicates of those in CPSMIT):
;       prcrlf - output a CR/LF
;       prtstr - output string in DE
;       rskp - return, skipping over error return
prcrlf: lxi     d,crlf
prtstr:
;  [17] added this  to avoid prtstr.. emulate function 9 call.
;	Works on most machines.
IF (torch OR px8 OR z80mu)
;
;       Modified print string as the CP/N (for Nut) system traps control
;       characters in a function 9 call.. rot its cotton socks.
        push    h
        push    d
        push    b
prtst1:
        ldax    d
        inx     d
        cpi     '$'             ; if a dollar then end of string
        jz      prtst2
        push    d
        mov     e,a
	mov	c,a		; also to c if its via conout in BIOS
        call    outcon          ; send it to the screen
        pop     d
        jmp     prtst1

prtst2: pop     b
        pop     d
        pop     h
        ret                     ; regs restored.. just in case
ENDIF	;(torch OR px8 OR z80mu)

IF NOT (torch OR px8 or z80mu)		;ie any machine that can send ctrl chrs via dos call 9
	PUSH	H
	PUSH	D
        push    b
        mvi     c,9     ; Dos call 9 (print a string)
        call    bdos
        pop     b
	POP	D
	POP	H
        ret             ; all done for good machines
ENDIF   ;NOT (torch OR px8 OR z80mu)

;
;	rskp - return to calling address + 3.
rskp:   pop     h               ; Get the return address
        inx     h               ; Increment by three
        inx     h
        inx     h
        pchl

;       Copy block of data
;       source in HL, destination in DE, byte count in BC
;       called by: cpxsys, mfname
;
mover:
;IF NOT z80              ; 8080's have to do it the hard way
;OBS assume its an 8080 for now - this will work on Z80s anyway.
        mov     a,m
        stax    d
        inx     h
        inx     d
        dcx     b
        mov     a,b
        ora     c
        jnz     mover
;ENDIF;NOT z80
;IF z80
;       db      0EDh,0B0h       ; Z80 LDIR instruction
;ENDIF;z80
        ret

;
;       Miscellaneous messages
;
crlf:   db      cr,lf,'$'
cfgmsg: db      'configured for $'
witmsg:	db	' with $'	; Its included if we get here ('with terminal')

IF NOT (osi OR crt OR px8)	; [29] got cursor control?
outln2:	db	']',cr,lf,cr,lf,'Number of packets:'
	db	cr,lf,'Number of retries:'
	db	cr,lf,'File name:$'
ENDIF;NOT (osi OR crt OR px8)

IF px8	; [29]
outln2:	db	']           Number of retries:', cr, lf
	db	'Number of packets:                     File name:$'
ENDIF ; px8 [29]

IF NOT (osi OR crt) ; [29]
outln3:	db	cr,lf,cr,lf	; debugging messages
	db	cr,lf,'Rpack:'
	db	cr,lf		; Blank line in case of long packet
	db	cr,lf,'Spack:$'
ENDIF ; NOT (osi OR crt) [29]

IF lasm
LINK CPXSWT.ASM
ENDIF	;lasm

