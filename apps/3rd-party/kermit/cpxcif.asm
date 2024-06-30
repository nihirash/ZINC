IF NOT lasm
.printx * CPXCIF.ASM *
ENDIF	;NOT lasm
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
;       This file contains the system dependent part for Cifer systems, and
;       is based on code contributed by John Shearwood of Birmingham
;       University.  This file was originally CPXTOR.ASM but now an 
;       FAMILY file on its own.
;
;       This file has code that supports Cifer 1886/2886 systems, running 
;       either CP/M Version 2.2 or 3.0, and driving the VL or AUX port.
;       xxx is a three letter abbrev. for the system you are adding.
;
; revision history:
;
; edit 2, 21 July, 1987 by OBSchou to bring it into line for use with 
;	CPXCOM.ASM.
;
; edit 1, 14 July by OBSchou for John Shearwood of Birmingham University, UK.
;	His edits ar based on the former CPXTOR.ASM family file.
;
;	edit 4, Apr 7 1987, JA Shearwood.  Add support for Cifer Aux port.
;	edit 2, Mar 17 1987, JA Shearwood Add support for Cifer CP/M Plus
;
; Keep module name, edit number, and last revision date in memory.
family: db      'CPXCIF.ASM (2)  14-Jul-87 $'
;
; Assembly time message to let me know I'm building the right version.
; LASM generates an 'S' error along with the message, which is messy, but
; better than trying to put everything inside a IF m80 OR mac80 conditional,
; because LASM doesn't like nested IF's, either.

IF cifer
.printx * Assembling Kermit-80 for Cifer 1886 *
ENDIF

IF cifer3
.printx * with CP/M Plus
ENDIF

IF cifaux
.printx * with AUX port
ENDIF

;
;=========================================================================
;       I/O Byte assignments (2-bit fields for 4 devices at loc 3)
;
;bits 6+7               LIST field
;       0               LIST is Teletype device (TTY:)
;       1               LIST is CRT device (CRT:)
;       2               LIST is Lineprinter (LPT:)
;       3               LIST is user defined (UL1:)
;
;bits 4+5               PUNCH field
;       0               PUNCH is Teletype device (TTY:)
;       1               PUNCH is high speed punch (PUN:)
;       2               PUNCH is user defined #1 (UP1:)
;       3               PUNCH is user defined #2 (UP2:)
;
;bits 2+3               READER field
;       0               READER is Teletype device (TTY:)
;       1               READER is high speed reader (RDR:)
;       2               READER is user defined #1 (UR1:)
;       3               READER is user defined #2 (UR2:)
;
;bits 0+1               CONSOLE field
;       0               CONSOLE is console printer (TTY:)
;       1               CONSOLE is CRT device (CRT:)
;       2               CONSOLE is in Batch-mode (BAT:);READER = Input,
;                       LIST = Output
;       3               CONSOLE is user defined (UC1:)
;
;=========================================================================

iobyte  EQU     03H     ;Location of I/O byte

IF cifer        ;[13]
batio   equ     80h             ; tty: as console
defio   equ     81h             ; crt: as console
z80     SET     TRUE           ; although it really is...
ENDIF;cifer [13]

defesc	EQU 	']'-100O        ;The default escape character.

; Select initial setting for VT-52 emulation flag.
vtval   EQU	1

IF iobyt	; only CP/M 2.2 and VL port use coniob in CPXCOM
		; rest use this one
coniob:	db	0		; default console bit pattern
ENDIF	;iobyt



sysxin:	;system initialisation not covered by sysinit
	mvi	a,defio
	sta	coniob

IF cifer AND NOT cifaux		; [JAS] Not if AUX port
        lxi     d,ciferi
        call    prtstr
ENDIF   ;cifer AND NOT cifaux

IF cifaux			; [JAS] Only Aux Port
        lhld    00047h		; Get address of CIOPS table
        lxi     d,6fh
        dad     d		; Calculate address of SETLNSPD
        shld    cifiop
        inx     h
        inx     h
        inx     h
        shld    ciflod		; Next entry LODEF
        lxi     d,81h-72h
        dad     d		; Calculate address of LIDEF
        shld    ciflid
        lhld    00045h		; Get address of SYSPTRS table
        lxi     d,12h		; Offset for LIDEF pointer
        dad     d		; Add to table address
        mov     e,m		; Get low byte LIDEF pointer
        inx     h
        mov     d,m		; Get high byte LIDEF pointer
        push    d
        inx     h		; LIPARM pointer next
        mov     a,m		; Get low byte of LIPARM pointer
        sta     ciptbl		; Keep
        inx     h
        mov     a,m		; Get high byte
        sta     ciptbl+1	; Keep
        lxi     d,1eh-15h	; Offset to LODEF
        dad     d
        mov     e,m		; Low byte
        inx     h
        mov     d,m		; High byte
        inx     h		; LOPARM is next entry
        mov     a,m
        sta     coptbl		; Keep low byte LOPARM
        inx     h
        mov     a,m
        sta     coptbl+1	; Keep high byte
; Now set up port for no parity 8 bits xon/xoff protocol both ways
        xchg			; LODEF into hl register
        push    h		; Needed later
        mvi     a,0
        mov     m,a		; Clear byte 0
        inx     h
        mov     m,a		; Clear byte 1
        inx     h
        mvi     a,099h		; XON/XOFF protocol, 8bits, no parity
        mov     m,a		; Flag into byte 2
        pop     h		; Restore address of LODEF
ciflod  equ     $+1
        call    $		; LODEF routine (poked above)
        pop     h		; LIDEF (PUSHed from de earlier)
        push    h		; Needed later
        mvi     a,0
        mov     m,a		; Clear byte 0
        inx     h
        mov     m,a		; Clear byte 1
        inx     h
        mvi     a,099h		; XON/XOFF protocol, 8bits, no parity
        mov     m,a		; Flag into byte 2
        pop     h		; Restore address of LIDEF
ciflid  equ     $+1
        call    $		; LIDEF routine (poked above)
        lhld    ciptbl		; Get current input speed
        mov     a,m
        sta     speed
        sta     speed+1
        mov     e,a
        mov     d,a
        call    sysspd		; Make sure ip and op are the same
ENDIF; cifer AND cifaux 

        ret                     ; return from system-dependent routine

;
;
;       system-dependent termination processing
;       If we've changed anything, this is our last chance to put it back.
sysexit:

IF cifer AND NOT cifaux
        lxi     d,cifero
        call    prtstr
ENDIF;cifer AND NOT cifaux

        ret

;
;       system-dependent processing for start of CONNECT command
;
syscon:
        ret

conmsg:         ; Messages printed when entering transparent (CONNECT) mode:
;
;
;       syscls - system-dependent close routine
;       called when exiting transparent session.
;
syscls:
        ret
;
;
;       sysinh - help for system-dependent special functions.
;       called in response to <escape>?, after listing all the
;       system-independent escape sequences.
;
sysinh:	lxi	d,inhlps	; we got options...
	call	prtstr		; print them.

        ret


;additional, system-dependent help for transparent mode
; (two-character escape sequences)
inhlps:

; [16] [18] have added super brain and Torch to the list of Breaking machines.

IF (cifer AND NOT cifaux)
        db      cr,lf,'B  Transmit a BREAK'
ENDIF   ;(cifer AND NOT cifaux)
        db      '$'                     ;[hh] table terminator

;
;       sysint - system dependent special functions
;       called when transparent escape character has been typed;
;       the second character of the sequence is in A (and in B).
;       returns:
;       non-skip: sequence has been processed
;       skip:   sequence was not recognized
sysint: ani     137O            ; convert lower case to upper, for testing...

; [19] have added superbrain and torch to the list

IF (cifer AND NOT cifaux)
        cpi     'B'             ; send break?
        jz      sendbr          ; yes, go do it.  return nonskip when through.
ENDIF   ;(cifer AND NOT cifaux)

        jmp     rskp            ; take skip return - command not recognized.

;

IF (cifer AND NOT cifaux)
sendbr: lxi     d,brkmes        ; send a break by sending esc * "
        call    prtstr          ; send to screen => breaks to port
        ret
ENDIF;cifer

;	sysflt - system-dependent filter.
;	called with the character in E.
;       preserves bc, de, hl.
;       note: <xon>,<xoff>,<del>, and <nul> are always discarded.
sysflt:
        mov     a,e             ; get character for testing
        ret

;       mdmflt - modem filter [30]
;       called with character to be sent to printer in E
;       with parity set as appropriate.
;       return with accumulator = 0 do do nothing,
;                               <> 0 to send char in E.
mdmflt:
        mov     a,e             ;[30] get character to test
        ret



;       prtflt - printer filter [30]
;       called with character to be sent to printer in E
;       returns with a = 0 to do nothing
;                    a <> 0 to print it.
;
;       this routine for those printer that automatically insert
;       a lf on cr, or cr for lf.  Should this be shifted to 
;       the system indep. stuff, in say 4.06?
prtflt:
        mov     a,e             ; [30] get character to test
        ret


;
;
; system-dependent processing for BYE command.
;  for apmmdm, heath, and lobo, hang up the phone.
sysbye:
        ret
;
;       This is the system-dependent command to change the baud rate.
;       DE contains the two-byte value from the baud rate table; this
;       value is also stored in 'speed'.
sysspd:

IF (cifer AND NOT cifaux); This one is wierd.. 
				; send an escape string to the screen to set rate.
        push    d               ; Save the data returned
        lxi     d,cifbrt                ; send the start of the escape string (esc ?)
        call    prtstr          ;
        pop     psw             ; get data into a (and flags>..)
        inr     a               ; need to send (a+1-1) 'N' to screen
        push    psw             ; we will need the data again
        call    cifnos          ; send a set of Ns to the screen
        pop     psw             ; (which then sets the VL line on the screen 
        call    cifnos          ; processor card)
        call    prcrlf          ; cr will terminate.. a crlf is handy
        ret

cifnos: dcr     a               ; if result = 0 then done
        jz      cifno1          ; if done then say 'Y' for yes.
        push    psw
        mvi     e,'N'           ; else send a string of Ns to screen processor
        mvi     c,dconio
        call    bdos
        pop     psw
        jmp     cifnos
cifno1: mvi     e,'Y'
        mvi     c,dconio
        call    bdos
        ret                     ; sent a sring of 0 or more N then a Y

cifbrt: db      esc,'?$'        ; start setting baud rate string
ENDIF ;cifer AND NOT cifaux

IF cifaux; [JAS] Set baud rate by massaging LIPARM/LOPARM and calling
				;CIOPS routine
; Set up speed byte in first location of tables
        lhld    coptbl		; Now sort out baud rate
        mov     a,e		; That's output speed
        mov     m,a
        xchg
        lhld    ciptbl
        mov     m,a		; Input speed
; Call CIOPS routine SETLNSPD with tables in appropriate rp's
cifiop  equ     $+1
        call    $		; Poked by sysinit
        ret

coptbl: dw      0
ciptbl: dw      0
ENDIF; cifaux

;
;       Speed tables
; (Note that speed tables MUST be in alphabetical order for later
; lookup procedures, and must begin with a value showing the total
; number of entries.  The speed help tables are just for us poor
; humans.

;       db      string length,string,divisor (2 identical bytes or 1 word)
; [Toad Hall]

IF cifer 
spdtbl: db      10h                     ;16 entries
        db      03h,'110$',     02h,02h
        db      04h,'1200$',    07h,07h
        db      05h,'134.5$',   03h,03h
        db      03h,'150$',     04h,04h
        db      04h,'1800$',    08h,08h
        db      05h,'19200$',   0fh,0fh
        db      04h,'2000$',    09h,09h
        db      04h,'2400$',    0ah,0ah
        db      03h,'300$',     05h,05h
        db      04h,'3600$',    0bh,0bh
        db      04h,'4800$',    0ch,0ch
        db      02h,'50$',      00h,00h
        db      03h,'600$',     06h,06h
        db      04h,'7200$',    0dh,0dh
        db      02h,'75$',      01h,01h
        db      04h,'9600$',    0eh,0eh

sphtbl: db      cr,lf,'   50     75    110    134.5  150    300    600   1200'
        db      cr,lf,' 1800   2000   2400   3600   4800   7200   9600  19200$'
ENDIF;cifer 

; The following conditionals were once a huge if not statement.  There
; wasn't enough room to add the lobo to the list, so it had to be broken
; into 2, which you can't do with an if not.  I redid it as two ifs and
; applied them to those that wouldn't set baud. [Hal Hostetler]
;
;       This is the system-dependent SET PORT command.
;       HL contains the argument from the command table.
sysprt:
IF iobyt
        mov     a,m             ;Get the I/O byte
        sta     prtiob          ;Save the desired IO byte for this port
        inx     h               ;Point at next entry
        mov     a,m             ;Get the output function
        sta     prtfun          ;Save it
ENDIF;iobyt

        ret
;
;
;
;       Port tables for GENERIC CPM 2.2
IF gener
; help text
prhtbl: db      cr,lf,'CRT device'
        db      cr,lf,'PTR device'
        db      cr,lf,'TTY device'
        db      cr,lf,'UC1 device'
        db      cr,lf,'UR1 device'
        db      cr,lf,'UR2 device$'

; command table
prttbl: db      06H             ;Six devices to choose from
        db      03H,'CRT$'
                dw      crtptb
        db      03H,'PTR$'
                dw      ptrptb
        db      03H,'TTY$'
                dw      ttyptb
        db      03H,'UC1$'
                dw      uc1ptb
        db      03H,'UR1$'
                dw      ur1ptb
        db      03H,'UR2$'
                dw      ur2ptb

; port entry table
; table entries are:
;       db      iobyte-value, BDOS output function, reserved
crtptb: db      crtio,conout,0
ptrptb: db      ptrio,punout,0
ttyptb: db      ttyio,conout,0
uc1ptb: db      uc1io,conout,0
ur1ptb: db      ur1io,punout,0
ur2ptb: db      ur2io,punout,0
ENDIF;gener

;
;
IF cifer                        ; no ports yet...
prttbl   EQU     0
prhtbl   EQU     0               ;
ENDIF; cifer

IF iobyt
prtfun: db      punout          ;Function to use for output to comm port
prtiob: db      batio           ;I/O byte to use for communicating
ENDIF;iobyt

IF NOT (iobyt OR lobo OR cifer)          ;[hh]
prttbl  equ     0               ; SET PORT is not supported
prhtbl  equ     0
ENDIF;NOT (iobyt OR lobo OR cifer)

;
;
;       selmdm - select modem port
;       selcon - select console port
;       selmdm is called before using inpmdm or outmdm;
;       selcon is called before using inpcon or outcon.
;       For iobyt systems, diddle the I/O byte to select console or comm port;
;       For Decision I, switches Multi I/O board to console or modem serial
;       port.  [Toad Hall]
;       For the rest, does nothing.
;       preserves bc, de, hl.
selmdm:
IF iobyt
        lda     prtiob          ;Set up for output to go to the comm port
        sta     iobyte          ;Switch byte directly
ENDIF;iobyt

        ret

selcon:
IF iobyt
        lda     coniob          ;Set up for output to go to the console port
        sta     iobyte          ;Switch directly
ENDIF;iobyt

        ret
;
;       Get character from console, or return zero.
;       result is returned in A.  destroys bc, de, hl.
;
inpcon:
IF NOT iobyt
        mvi     c,dconio        ;Direct console I/O BDOS call.
        mvi     e,0FFH          ;Input.
        call    BDOS
ENDIF;NOT iobyt

IF iobyt
        call    bconst          ;Get the status
        ora     a               ;Anything there?
        rz                      ;No, forget it
        call    bconin          ;Yes, get the character
ENDIF;iobyt
        ret
;
;
;       Output character in E to the console.
;       destroys bc, de, hl
;
outcon:

IF NOT iobyt
        mvi     c,dconio        ;Console output bdos call.
        call    bdos            ;Output the char to the console.
ENDIF;NOT iobyt

IF iobyt
        mov     c,e             ;Character
        call    bcnout          ;to Console
ENDIF;iobyt
        ret
;
;
;       outmdm - output a char from E to the modem.
;               the parity bit has been set as necessary.
;       returns nonskip; bc, de, hl preserved.
outmdm:
IF inout
        in      mnprts          ;Get the output done flag.
        ani     output          ;Is it set?
        jz      outmdm          ;If not, loop until it is.
        mov     a,e
        out     mnport          ;Output it.
        ret
ENDIF;inout

IF iobyt
;**** Note that we enter from outpkt with the I/O byte already set up for
;  output to go to the comm port
        push    h
        push    b
        lda     prtfun          ;Get the output function
        mov     c,a             ;Into C
        call    bdos            ;And output the character
        pop     b
        pop     h
        ret
ENDIF;iobyt

IF cifer3			; [JAS]
        push    h
        push    b
        mvi     c,auxout        ;Output to the aux output device
        call    bdos
        pop     b
        pop     h
        ret
ENDIF;cifer3


;
;
;       get character from modem; return zero if none available.
;       for IOBYT systems, the modem port has already been selected.
;       destroys bc, de, hl.
inpmdm:
IF iobyt
        call    bconst          ;Is Char at COMM-Port?
        ora     a               ;something there?
        rz                      ; return if nothing there
        call    bconin          ; data present. read data.
ENDIF;iobyt

IF inout
;Note: modem port should already be selected for mdI.  [Toad Hall]
        in      mnprts          ;Get the port status into A.
        ani     input           ;See if the input ready bit is on.
        rz                      ;If not then return.
        in      mnport          ;If so, get the char.
ENDIF;inout

IF cifer3			; [JAS]
        mvi     c,auxist
        call    bdos            ;is char at auxin?
        ora     a               ;something there?
        rz                      ;no
        mvi     c,auxin
        call    bdos            ;read char from auxin
ENDIF;cifer3

ret                     ; return with character in A


;
;       flsmdm - flush comm line.
;       Modem is selected.
;       Currently, just gets characters until none are available.

flsmdm: call    inpmdm          ; Try to get a character
        ora     a               ; Got one?
        jnz     flsmdm          ; If so, try for another
        ret                     ; Receiver is drained.  Return.


;
;
;       lptstat - get the printer status. Return a=0 if ok, or 0ffh if not.
lptstat:
IF iobyte       ;[33]
        call    bprtst          ; get status
ENDIF   ;iobyte[33]
IF NOT iobyte   ;[33]
        xra     a               ; assume it is ok.. this may not be necessary
ENDIF   ;iobyte [33]
        ret
;
;
;       outlpt - output character in E to printer
;       console is selected.
;       preserves de.
outlpt:
        push    d               ; save DE in either case
        call    prtflt          ; go through printer filter [30]
        ana     a               ; if A = 0 do nothing,
        jz      outlp1          ; [30] if a=0 do nothing

IF NOT iobyte
        mvi     c,lstout
        call    bdos            ;Char to printer
ENDIF;NOT iobyt
IF iobyt
        mov     c,e
        call    blsout
ENDIF;iobyt

outlp1: pop     d               ; restore saved register pair
        ret
;
;
;       Screen manipulation routines
;       csrpos - move to row B, column C
;
;       csrpos for terminals that use a leadin sequence followed
;        by (row + 31.) and (column + 31.)
;
IF cifer                        ; [14] cifer does it colums then rows.. swap b and c
csrpos: push    b               ; save coordinates
        lxi     d,curldn        ; get cursor leadin sequence
        call    prtstr          ; print it
        pop     h               ; restore coordinates
        mov     a,l             ; [obs] get column
        adi     (' '-1)         ; space is column one
        mov     e,a
        push    h
        call    outcon          ; output row
        pop     h
        mov     a,h             ; [obs] get row
        adi     (' '-1)         ; space is row one
        mov     e,a
        jmp     outcon          ; output it and return
ENDIF; cifer 

;
;
; delchr - make delete look like a backspace.  Unless delete is a printing
;       character, we just need to print a backspace. (we'll output clrspc
;       afterwards)
;       For Kaypro and Vector General, delete puts a blotch on the screen.
;       For Apple and Osborne 1, delete moves but doesn't print.
delchr:
	mvi	e,bs
	call	outcon

; erase the character at the current cursor position
clrspc: mvi     e,' '
        call    outcon
        mvi     e,bs            ;get a backspace
        jmp     outcon

; erase the current line
clrlin: lxi     d,eralin
        jmp     prtstr

; erase the whole screen, and go home. preserves b (but not c)
clrtop: lxi     d,erascr
        jmp     prtstr


IF cifer AND NOT cifaux        ;[13]
ttytyp: db      'Cifer 1886 (Parity set to space only)$'
ENDIF; cifer AND NOT cifaux

IF cifaux			;JAS
ttytyp: db      ' Cifer 1886 $'
ENDIF; cifaux

IF cifer			;[JAS]
sysver: db      ' Cifer 1886 $'         ;
outlin: db      esc,'J',cr,lf,tab,tab,'$'
eralin: db      esc,'^K$'               ;Clear to end of line.
erascr: db      esc,'J$'                ;Clear screen and go home.
curldn: db      esc,'P$'                ;Cursor lead-in
ttab:                                   ;Table start location.
ta:     db      esc,'A$',0              ;Cursor up.
tb:     db      esc,'@$',0              ;Cursor down.
tc:     db      esc,'C$',0              ;Cursor right.
td:     db      esc,'D$',0              ;Cursor left.
te:     db      esc,'J',0,0             ;Clear screen and home cursor
tf:     db      '$',0,0,0               ;(can't) Enter Graphics mode
tg:     db      '$',0,0,0               ;(can't) Exit Graphics mode
th:     db      esc,'H$',0              ;Cursor home.
ti:     db      esc,'@$',0              ;reverse linfeed
tj:     db      esc,'B$',0              ;Clear to end of screen
tk:     db      esc,'K$',0              ;Clear to end of line.
ENDIF;cifer
;
IF cifer AND NOT cifaux			;[JAS]
; Setup string for the Cifer.. called as a prtstr param. from sysinit
ciferi: db      esc,'/'                 ;Setup cifer for on line
        db      esc,'*['                ; direct mode on
        db      esc,'%'                 ; protocol on host line on
        db      esc,'*~x'               ; protocol is xon/xoff
        db      esc,'*('                ; protocol out on host is xon/xoff
        db      esc,'?  NNNY',cr        ; set VL port to space parity
                                        ; It cannot do NONE.. Thanks a lot
        db      '$'                     ; all done
; Finish string for the Cifer.. called as a prtstr param. from sysexit
cifero: db      esc,'&'			; Host input protocol off
        db      esc,'*)'		; Host output protocol off
        db      esc,'*]'		; Direct mode off
        db      esc,'\'			; Setup cifer for off line
        db      '$'
; Break string for cifer VL port.
brkmes: db      esc,'*"$'               ;Send a break command string
ENDIF;cifer AND NOT cifaux     [13]

ovlend	equ	$	; End of overlay

	END

