IF NOT lasm
.printx * CPXHEA.ASM *
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
;       This file contains the system-dependent code and data for KERMIT
;       specific to the Heath/Zenith H89 and Z100, the Telcon Zorba,
;       and the OEM ScreenTyper.  All but the latter use VT52 (or a
;       replica thereof) for screen output; the ScreenTyper uses the
;       same serial port chip as the H89 (an Intel 8250).
;
; revision history:
;
; Edit 4, 31-Aug-1989 by Mike Freeman, 301 N.E. 107th Street; Vancouver wa
;	98685 USA; Telephone (206)574-8221:  Added Baud-rate Selection and
;	Break-sending ability for the Telcon Zorba portable.
;
; edit 3, 22 July, 1987 by OBSchou to massage code to conform to new set 
;	of overlay files (stripping out common code to CPXCOM.ASM)
;
; edit 2 by OBSchou to add in old Kermit-80 V3.5 heath-8 code, formerly
;	in CPM directory.  Entry from CP/M file:
;
;	This file contains an upgrade to the CPMBASE.M80 KERMIT 
;	to allow setting and display of baud rates, a bug fix in 
;	telnet, and an extension of the HELP to show GET (which works 
;	in this release, on the H8). Look for the new symbol "h8quad" 
;	(for the heath quad i/o board that it uses) in the conditionals. 
;	Note that the Heath H8 is NOT the same machine as the H89. The H89 
;	code does not run 'as is' on the H8, and does NOT initialize the 
;	UART. Also there was a bug in the telnet section that is fixed 
;	here, though I expect that it has already been found and fixed 
;	by now - this is from the DECUS FALL 83 tape. The comments were 
;	stripped out of this file to make it small enough for my H8 to 
;	assemble, however, I have put the first section back in to make 
;	it easier for you to identify. Thanks for a nice product to use 
;	and work on. Major insertions are heavily commented, edit as needed.
;
;	This modification done by John Mealing, InteCom Inc, 601 Intecom Dr.,
;	Allen, TX 75002 (214)797-9141, x-2493, 5 Nov 84.
;
;	[OBSchou notes: This is the header, and the bugs in telnet are 
;	unknown.  telnet routine has been substantially changed anyway with
;	4.08-4.09 revision.  As for the major insertions: they probably went
;	with the 4.xx re-write.  I am unable to test this version: can 
;	anyone else do so??]
;
;
; edit 01 5th Mar 1987 by M J Carter, Nottingham Uni [majoc]
;       Split off from CPXSYS.ASM, in order to install support for
;       the OEM ScreenTyper.  I can't test anything other than the
;       ScreenTyper as I haven't the hardware.  Any offers?
;               Thanks are due to Paul Bartlett of John Elmer
;       Electronics Ltd, who provided me with his modified sources
;       for (a slightly antiquated) CP/M 4.05 Kermit on which this
;       is based.
;       
; Keep module name, edit number, and last revision date in memory.
;sysedt:        db      'CPXSYS.ASM (35) 01-Dec-86 $'
; [majoc 870305] Now in CPXFRK.  I'll have to consult on this ...
;
;
;
; Assembly time message to let me know I'm building the right version.
; LASM generates an 'S' error along with the message, which is messy, but
; better than trying to put everything inside a IF m80 OR mac80 conditional,
; because LASM doesn't like nested IF's, either.

IF heath
.printx * Assembling KERMIT-80 for the Heath/Zenith 89 *
ENDIF

IF h8quad
.printx * Assembling KERMIT-80 for the Heath-8 with Quad IO board *
ENDIF

IF z100
.printx * Assembling KERMIT-80 for the Heath/Zenith Z100 *
ENDIF

IF telcon
.printx * Assembling KERMIT-80 for the Telcon Zorba *
ENDIF

IF scntpr
.printx * Assembling KERMIT-80 for the OEM ScreenTyper *
ENDIF
;

;

IF heath
mnport  EQU     330O    ;Modem data port
ENDIF ; heath

IF h8quad
mnport  EQU     330O            ;all port addresses can be set by user -
mnprts  EQU     mnport + 05     ;   in octal cause heath wrote documents that
output  EQU     20H             ;   way -- relative addressing on the UART
input   EQU     01H             ;   registers, just to be nice
baudls  EQU     mnport          ;ls baud divisor latch when DALB set
baudms  EQU     mnport + 1      ;ms baud divisor latch when DALB set
linctl  EQU     mnport + 3      ;line control register
modctl  EQU     mnport + 4      ;MODEM control register
dalbon  EQU     80H             ;enables speed selection
linset  EQU     03H             ;force hardware 8 bit, even parity
;
; The line control register (linctl) is bit mapped as follows:
;       bit #   function           value
;       0,1     select word size   00 -> 5 bit,   10 -> 7 bit
;                                  01 -> 6 bit,   11 -> 8 bit
;       2       select stop bits   0 -> 1 stop bit,  1 -> 1 1/2 for 5 bit,
;                                                    1 -> 2 for 6 bit words
;       3       parity enable      0 -> no parity,  1 -> parity as set by 4
;       4       Even parity select 0 -> Odd parity,   1 -> Even parity
;       5       Stick parity       1 -> Parity of bit 4 is inverted
;       6       Break control      1 -> output forced to spacing (break)
;       7       DALB               1 -> access divisor latches to set baud rate
;
; The value in linset is loaded into linctl when KERMIT comes up.
;
ms300   EQU     001O            ;set for 300 baud as default
ls300   EQU     200O
rtsoff  EQU     20O             ;direct control of modem lines
rtson   EQU     11O
z80	EQU	FALSE		;[2] or is it?
ENDIF	;h8quad

IF scntpr
mnport  EQU     8       ;Modem data port
ENDIF ; scntpr
IF heath OR scntpr

;       Definitions for the 8250 ACE

acerbr  EQU     0       ; ACE Receiver Buffer Register offset (R/O) (DLAB = 0)
acethr  EQU     0       ; ACE Transmitter Holding Register offset (W/O)
acedll  EQU     0       ; ACE Divisor Latch (Low)       (DLAB = 1)
acedlh  EQU     1       ; ACE Divisor Latch (High)      (DLAB = 1)
aceier  EQU     1       ; ACE Interrupt Enable Register (DLAB = 0)
aceiir  EQU     2       ; ACE Interrupt Identification Register
acelcr  EQU     3       ; ACE Line Control Register
acemcr  EQU     4       ; ACE Modem Control Register
acelsr  EQU     5       ; ACE Line Status Register offset
acemsr  EQU     6       ; ACE Modem Status Register

ace8bw  EQU     00000011b ; 8 bit words
acesb   EQU     01000000b ; set break
acedla  EQU     10000000b ; divisor latch access
acedtr  EQU     00000001b ; data terminal ready
aceloo  EQU     00010000b ; loopback mode
acedr   EQU     00000001b ; data ready
acethe  EQU     00100000b ; transmitter holding register empty

;mnport EQU     330O    ;Modem data port
; [35a: majoc 870305] Shifted up above joint IF, to save nesting.
mnprts  EQU     mnport+acelsr   ;Modem status port
output  EQU     acethe  ;Transmitter empty
input   EQU     acedr   ;Input data available
z80     EQU     TRUE    ;H89 uses the Z80
ENDIF;heath OR scntpr

IF z100
mnport  EQU     0ECH    ;Modem data port
mnprts  EQU     0EDH    ;Modem status port
output  EQU     01H     ;Transmitter empty
input   EQU     02H     ;Input data available
z80     EQU     FALSE   ;[hh] this one's an 8085.
ENDIF;z100


IF telcon
MNPORT  EQU     20H     ;Modem data port
MNPRTS  EQU     21H     ;Modem status port
OUTPUT  EQU     01H     ;Transmitter empty
INPUT   EQU     02H     ;Input data available
BRPORT	EQU	00H		;8254-2 Baud Rate Generator Timer for Port A
COMMND	EQU	03H		;8254-2 Timer Control Port
z80     EQU     TRUE		;[MF]A real Z80
ENDIF;telcon
;

IF telcon 
defesc  EQU     ']'-100O        ;The default escape character.
ENDIF;telcon

IF heath OR h8quad OR z100 OR scntpr
defesc  EQU     '\'-100O        ;The default is Control \ -- it's easier B.E.
ENDIF;heath OR h8quad OR z100 OR scntpr

; Select initial setting for VT-52 emulation flag.
IF (heath OR h8quad OR z100 OR telcon)
vtval   EQU     0               ;  we don't need VT52 emulation
ENDIF;heath OR h8quad OR z100 OR telcon OR vt52 [OBS question - ok for h8quad?]
; If none of the above, default to VT52-EMULATION ON.
IF scntpr
vtval   EQU     1               ;  we do VT52 emulation
ENDIF;scntpr


;
;       Family is the string used in VERSION to say which of several 
;       smaller overlay files are used.  These are (will be) derived from 
;       the juge CPXSYS.ASM file, in which case we will never get here.  
;       Just a Dollar, but put a sting in for a family of machines.
;
family: db      'CPXHEA.ASM (4)  31-Aug-1989$' ; Used for family versions....

;
sysxin:		; continuation of initialisation code
IF heath OR scntpr
;
;       System dependent startup for H89 and OEM ScreenTyper
;

        call    mdmofl          ; keep the line safe from garbage

;       First, tell Kermit the modem port's current speed
        in      mnport+acelcr
        ori     acedla
        out     mnport+acelcr   ; access the ACE's divisor latch
        in      mnport+acedll   ; get the low byte
        sta     speed
        in      mnport+acedlh   ; and the high byte
        sta     speed+1

;       Now set up the port for Kermit
        mvi     a,ace8bw        ; 8 data bits, 1 stop bit, no parity
        out     mnport+acelcr
        in      mnport+acemcr
        ori     acedtr          ; raise DTR (just in case)
        out     mnport+acemcr
        call    mdmonl          ; and put the ACE back on line
        ret

;       Take the ACE off line before modifying its state
mdmofl:
        in      mnport+aceier   ; save the ACE's interrupt state
        sta     iersav
        xra     a
        out     mnport+aceier   ; and disable ACE interrupts
        in      mnport+acemcr   ; now put the ACE in loopback mode
        ori     aceloo
        out     mnport+acemcr
        ret

;       Put the ACE back on line
mdmonl:
        in      mnport          ; flush left-over garbage in the receive buffer
        mvi     a,7             ; wait about 2 300-baud character times
        call    delay
        in      mnport          ; and flush more garbage
        in      mnport+acemcr   ; take the ACE out of loopback mode
        ani     0FFH-aceloo
        out     mnport+acemcr
        lda     iersav
        out     mnport+aceier   ; and restore the ACE's interrupt state
        ret

iersav: ds      1
ENDIF;heath OR scntpr

IF h8quad
h8init: lxi	d,180h		; [2] set up for 300 baud
h8baud: mvi     a,rtsoff        ;disable modem for now
        out     modctl
        mvi     a,dalbon        ;set for UART speed programming
        out     linctl
	mov	a,d		; [2] get ms bits for rate
        out     baudms
	mov	a,e		; [2] get ls bits for rate
        out     baudls
        mvi     a,linset        ;force 8 bit, no parity and clear dalb
        out     linctl
        in      mnport          ;clear the recieve side
        mvi     a,rtson         ;get ready
        out     modctl          ;modem is on and ready to go
ENDIF                           ;h8quad

        ret                     ; return from system-dependent routine

;
;
;       system-dependent termination processing
;       If we've changed anything, this is our last chance to put it back.
sysexit:
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
sysinh:
IF heath OR scntpr  OR telcon;[4]
        lxi     d,inhlps        ; we got options...
        call    prtstr          ; print them.
ENDIF;heath OR scntpr  OR telcon

        ret


;additional, system-dependent help for transparent mode
; (two-character escape sequences)
inhlps:
IF heath OR scntpr  OR telcon;[4]
        db      cr,lf,'B  Transmit a BREAK'
ENDIF;heath OR scntpr  OR telcon

IF heath OR scntpr 
        db      cr,lf,'D  Drop the line'
ENDIF;heath OR scntpr 

        db      '$'                     ;[hh] table terminator

;
;       sysint - system dependent special functions
;       called when transparent escape character has been typed;
;       the second character of the sequence is in A (and in B).
;       returns:
;       non-skip: sequence has been processed
;       skip:   sequence was not recognized
sysint: ani     137O            ; convert lower case to upper, for testing...

IF heath OR scntpr
        cpi     'D'             ; drop line?
        jnz     intc00          ; no:  try next function character

mdmdrp: in      mnport+acemcr   ; (we also get here from sysbye)
        ani     0FFH-acedtr
        out     mnport+acemcr   ; yes: drop DTR
        mvi     a,50            ;      for half a second
        call    delay
        in      mnport+acemcr
        ori     acedtr
        out     mnport+acemcr   ;      and then restore it
        ret
intc00:
ENDIF;heath OR scntpr

IF heath OR scntpr OR telcon;[4]
        cpi     'B'             ; send break?
        jz      sendbr          ; yes, go do it.  return nonskip when through.
ENDIF;heath OR scntpr OR telcon
      jmp     rskp            ; take skip return - command not recognized.


;
IF heath OR scntpr
;
;       Send BREAK on H89 or ScreenTyper
;
sendbr: in      mnport+acelcr
        ori     acesb
        out     mnport+acelcr   ; set ACE break condition
        mvi     a,30
        call    delay           ; wait 300 milliseconds
        in      mnport+acelcr
        ani     0FFH-acesb
        out     mnport+acelcr   ; and clear ACE break condition
        ret

ENDIF;heath OR scntpr
;
IF telcon			;[4]
;
;	Send break on Telcon Zorba
;
sendbr:	mvi	a,3fH		;DTR normal, break on
	out	mnprts		;Set break on
	mvi	a,30		;Wait 300 ms
	call	delay		;...
	mvi	a,37h		;DTR normal, tx, rx enabled
	out	mnprts		;Restore normal condition
	ret			;and return
;
ENDIF ;telcon

;
;
;       sysflt - system-dependent filter
;       called with character in E.
;       if this character should not be printed, return with A = zero.
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
;  for apmmdm, heath, scntpr, and lobo, hang up the phone.
sysbye:
IF heath OR scntpr
        call    mdmdrp          ;  Sleazy but effective
ENDIF;heath OR scntpr

        ret
;
;       This is the system-dependent command to change the baud rate.
;       DE contains the two-byte value from the baud rate table; this
;       value is also stored in 'speed'.
sysspd:

IF heath OR scntpr
;
;       Set speed for H89
;
        call    mdmofl          ; keep the line safe from garbage
        in      mnport+acelcr
        ori     acedla
        out     mnport+acelcr   ; access the ACE's divisor latch
        mov     a,e             ; low byte of speed is in E
        out     mnport+acedll   ; set the low byte
        mov     a,d             ; high byte of speed is in D
        out     mnport+acedlh   ; set the high byte
        in      mnport+acelcr
        ani     0FFH-acedla
        out     mnport+acelcr   ; de-access the ACE's divisor latch
        call    mdmonl          ; and put the ACE back on line
ENDIF;heath OR scntpr

IF h8quad	;[2][obs] A bit of guesswork this.  Enter with date in de
	call	h8baud		; [2] routine is in initialisation bit
ENDIF	; h8quad[2]
;
IF telcon			;[4]
	MVI	A,36H		;Set square wave
	OUT	COMMND		;...
	MOV	A,E		;Get LSB of Baud rate
	OUT	BRPORT		;Send to generator
	MOV	A,D		;Get msb of baud rate
	OUT	BRPORT		;Send to Baud rate generator
ENDIF ;telcon
;
	ret

;
;
;       Speed tables
; (Note that speed tables MUST be in alphabetical order for later
; lookup procedures, and must begin with a value showing the total
; number of entries.  The speed help tables are just for us poor
; humans.
;
;       db      string length,string,divisor (2 identical bytes or 1 word)
; [Toad Hall]

IF heath
;
;       Speed selection table for H89  (OK, so I got a little carried away...)
;

spdtbl: db      19              ; 19 entries
        db      3,'110$'
        dw      1047
        db      4,'1200$'
        dw      96
        db      5,'134.5$'
        dw      857
        db      4,'1800$'
        dw      64
        db      5,'19200$'
        dw      6
        db      3,'200$'
        dw      576
        db      4,'2400$'
        dw      48
        db      3,'300$'
        dw      384
        db      4,'3600$'
        dw      32
        db      5,'38400$'
        dw      3
        db      3,'450$'
        dw      256
        db      4,'4800$'
        dw      24
        db      2,'50$'
        dw      2304
        db      5,'56000$'
        dw      2
        db      3,'600$'
        dw      192
        db      4,'7200$'
        dw      16
        db      2,'75$'
        dw      1536
        db      3,'900$'
        dw      128
        db      4,'9600$'
        dw      12

sphtbl: db      cr,lf
        db      '    50    75   110 134.5   200   300   450   600   900  1200'
        db      cr,lf,'  1800  2400  3600  4800  7200  9600 19200 38400 56000$'
ENDIF;heath

IF h8quad
spdtbl:	db	6	;[2] 6 entries
        db      3,'300$',	1,80h	; divisor for 300 baud
        db      3,'600$',	0,0c0h
        db      4,'1200$',	0,60h
        db      4,'2400$',	0,30h
        db      4,'4800$',	0,18h
        db      4,'9600$',	0,0ch
;
; The strings to display the speed selected from the table above
;
sphtbl:	db	cr,lf,' 300   600  1200  2400  4800  9600$'
ENDIF                                   ;h8quad

IF scntpr
; [35a: majoc 870305]
;
;       Speed selection table for ScreenTyper
;

spdtbl: db      14              ; 14 entries
        db      3,'110$'
        dw      470H
        db      4,'1200$'
        dw      68H
        db      5,'134.5$'
        dw      3a1H
        db      4,'1800$'
        dw      45H
        db      5,'19200$'      ; This was in PB's table, but not in the
        dw      7H              ; accompanying text string.  Oversight?
;       db      3,'200$'
;       dw      576
        db      4,'2400$'
        dw      34H
        db      3,'300$'
        dw      1a1H
        db      4,'3600$'
        dw      23H
;       db      5,'38400$'
;       dw      3
;       db      3,'450$'
;       dw      256
        db      4,'4800$'
        dw      1aH
        db      2,'50$'
        dw      964H
;       db      5,'56000$'
;       dw      2
        db      3,'600$'
        dw      0d0H
        db      4,'7200$'
        dw      11H
        db      2,'75$'
        dw      683H
;       db      3,'900$'
;       dw      128
        db      4,'9600$'
        dw      0dH

sphtbl: db      cr,lf,'    50    75   110 134.5   300   600   1200'
        db      cr,lf,'  1800  2400  3600  4800  7200  9600 (19200?)$'
ENDIF;scntpr
;
IF telcon			;[4]
;
;	Speed selection tables for the Telcon Zorba (I overdid it, also)
;
;	**NOTE** that when Kermit is first executed, the baud rate is
;	unknown to Kermit, having been set by CP/M upon cold-boot, SETUP.COM,
;	another communications program, etc.  The easiest way to insure that
;	the baud rate is known upon Kermit start-up is to set it
;	in KERMIT.INI.
;
spdtbl:	db	20		;[4]Number of entries (some of these
				;speeds are *weird* but the Zorba
				;supports them so I'll put them in
	db	3,'110$'
	dw	4545
	db	4,'1200$'
	dw	417
	db	5,'134.5$'
	dw	3717
	db	3,'150$'
	dw	3333
	db	4,'1760$'
	dw	284
	db	4,'1800$'
	dw	278
	db	5,'19200$'
	dw	26
	db	3,'200$'
	dw	2500
	db	4,'2000$'
	dw	250
	db	4,'2400$'
	dw	208
	db	3,'300$'
	dw	1667
	db	4,'3520$'
	dw	142
	db	4,'3600$'
	dw	139
	db	4,'4800$'
	dw	104
	db	2,'50$'
	dw	10000
	db	3,'600$'
	dw	833
	db	4,'62.5$'
	dw	8000
	db	4,'7200$'
	dw	69
	db	2,'75$'
	dw	6667
	db	4,'9600$'
	dw	52
;
;	Help table
;
sphtbl: db      cr,lf
        db      '    50    62.5   75 110   134.5   150   200   300   600   1200'
        db      cr,lf,'  1760  1800  2000  2400  3520  3600  4800 7200'
	db	cr,lf,'  9600  19200$'
;
ENDIF ;Telcon

; The following conditionals were once a huge if not statement.  There
; wasn't enough room to add the lobo to the list, so it had to be broken
; into 2, which you can't do with an if not.  I redid it as two ifs and
; applied them to those that wouldn't set baud. [Hal Hostetler]
IF z100 
spdtbl  equ     0               ; SET BAUD not supported.
sphtbl  equ     0
ENDIF;z100 
;
;
;       This is the system-dependent SET PORT command.
;       HL contains the argument from the command table.
sysprt:
        ret
;
prttbl  equ     0               ; SET PORT is not supported
prhtbl  equ     0
;
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
        ret

selcon:
        ret

;       Get character from console, or return zero.
;       result is returned in A.  destroys bc, de, hl.
;
inpcon:
IF NOT iobyt
        mvi     c,dconio        ;Direct console I/O BDOS call.
        mvi     e,0FFH          ;Input.
        call    BDOS
ENDIF;NOT iobyt

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

;
;
;       get character from modem; return zero if none available.
;       for IOBYT systems, the modem port has already been selected.
;       destroys bc, de, hl.
inpmdm:
IF NOT iobyt	;[2] this routine not in submitted file, so I guess 
		; guess this is what it is supposed to do.
	in	mnprts		; input status port
	ani	input		; anything t read in?
	rz			; nope
	in	mnport		; else read in the data
	ret			; return with character in A
ENDIF ; NOT iobyte [2]

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
;       lptstat - get the printer status. Return a=0ffh if ok, or 0 if not.
lptstat:
        call	bprtst		; assume it is ok.. this may not be necessary
        ret

;
;       outlpt - output character in E to printer
;       console is selected.
;       preserves de.
outlpt:
        push    d               ; save DE in either case
        call    prtflt          ; go through printer filter [30]
        ana     a               ; if A = 0 do nothing,
        jz      outlp1          ; [30] if a=0 do nothing

IF NOT iobyt
        mvi     c,lstout
        call    bdos            ;Char to printer
ENDIF;NOT iobyt
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
csrpos: push    b               ; save coordinates
        lxi     d,curldn        ; get cursor leadin sequence
        call    prtstr          ; print it
        pop     h               ; restore coordinates
        mov     a,h             ; get row
        adi     (' '-1)         ; space is row one
        mov     e,a
        push    h
        call    outcon          ; output row
        pop     h
        mov     a,l             ; get column
        adi     (' '-1)         ; space is column one
        mov     e,a
        jmp     outcon          ; output it and return

;
; delchr - make delete look like a backspace.  Unless delete is a printing
;       character, we just need to print a backspace. (we'll output clrspc
;       afterwards)
;       For Kaypro and Vector General, delete puts a blotch on the screen.
;       For Apple and Osborne 1, delete moves but doesn't print.
delchr:
        mvi     e,bs            ;get a backspace
        jmp     outcon

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

IF telcon
sysver: db      'Telcon Zorba$'
ENDIF;telcon

IF heath
sysver: db      'Heath/Zenith 89$'
ENDIF;heath

IF h8quad
sysver:	db	'Heath H8 with quad I/O card$'
ENDIF

IF z100
sysver: db      'Heath/Zenith Z-100 CP/M$'
ENDIF;z100

IF scntpr
; [35a: majoc 870305]
sysver: db      'OEM ScreenTyper: 4MHz Z80 running OS/M$'
ENDIF;scntpr

IF heath OR h8quad OR z100 OR telcon
outlin: db      esc,'H',esc,'J',cr,lf,tab,tab,'$'
erascr: db      esc,'H',esc,'J$'        ;Clear screen and go home.
eralin: db      cr,esc,'K$'             ;Clear line.
curldn: db      esc,'Y$'                ;cursor leadin
ttab:                                   ;Table start location.
ta:     db      esc,'A$',0              ;Cursor up.
tb:     db      esc,'B$',0              ;Cursor down.
tc:     db      esc,'C$',0              ;Cursor right.
td:     db      esc,'D$',0              ;Cursor left
te:     db      esc,'E$',0              ;Clear display
tf:     db      esc,'F$',0              ;Enter Graphics Mode
tg:     db      esc,'G$',0              ;Exit Graphics mode
th:     db      esc,'H$',0              ;Cursor home.
ti:     db      esc,'I$',0              ;Reverse linefeed.
tj:     db      esc,'J$',0              ;Clear to end of screen.
tk:     db      esc,'K$',0              ;Clear to end of line.
ENDIF;heath OR h8quad OR z100 OR telcon
;

IF scntpr       ; [35a: majoc 870305]
outlin: db      1aH,    cr, lf, '$'
erascr: db      1aH,    '$'             ;Clear screen and go home.
eralin: db      cr,esc,'*$'             ;Clear line.
curldn: db      esc,'=$'                ;cursor leadin
ttab:                                   ;Table start location.
ta:     db      1eH,'$',0,0             ;Cursor up.
tb:     db      1fH,'$',0,0             ;Cursor down.
tc:     db      1cH,'$',0,0             ;Cursor right.
td:     db      1dH,'$',0,0             ;Cursor left
te:     db      1aH,'$',0,0             ;Clear display
tf:     db      0,0,0,0                 ;(Can't)Enter Graphics Mode
tg:     db      0,0,0,0                 ;(Can't)Exit Graphics mode
th:     db      15H,'$',0,0             ;Cursor home.
ti:     db      1eH,'$',0,0             ;Reverse linefeed.
tj:     db      esc,'%$',0              ;Clear to end of screen.
tk:     db      esc,'*$',0              ;Clear to end of line.
ENDIF;scntpr

ovlend  EQU     $       ; End of overlay
	END		; Phew ... [majoc 870305]
