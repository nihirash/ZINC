IF NOT lasm
.printx * CPXSYS.ASM *
ENDIF	;NOT lasm
;	KERMIT - (Celtic for "FREE")
;
;	This is the CP/M-80 implementation of the Columbia University
;	KERMIT file transfer protocol.
;
;	Version 4.0
;
;	Copyright June 1981,1982,1983,1984,1985
;	Columbia University
;
; Originally written by Bill Catchings of the Columbia University Center for
; Computing Activities, 612 W. 115th St., New York, NY 10025.
;
; Contributions by Frank da Cruz, Daphne Tzoar, Bernie Eiben,
; Bruce Tanner, Nick Bush, Greg Small, Kimmo Laaksonen, Jeff Damens, and many
; others.
;
;	This file contains the system-dependent code and data for KERMIT.
;	It will be probably be broken into independent files to generate
;	overlays for the various systems, one or more overlay possible
;	from each file.	 For now, we will leave it in one piece.
;
; revision history:
;
;
; Edit 40, 28-Aug-89 by Mike Freeman of Bonneville Power Administration,
;	P.O. Box 491, Vancouver WA 98666 USA, Telephone (206)690-2307:
;	Home address:  301 N.E. 107th Street; Vancouver, WA 98685 USA
;	Home telephone:  (206)574-8221
;	added support for Hewlett-Packard HP-125 Business Assistant computer
;	running a HP-modified CP/M Version 2.2; communications on
;	DAta Comm 1 or Data Comm 2 (8th-bit quoting must be used on
;	Data Comm 2 to transfer binary files as Data Comm 2 only supports
;	a 7-bit data path); printer cannot be used with communications on
;	Data Comm 2 (the printer port).
; edit 39, 4 August, 1987b by OBSchou for Charles Lasner re. DECMATE II
;	fixes to set xon/off control off for the duration of Kermit-80.
;
;	His header reads:
;
;	IBM mode restore program
;
;	This routine must be run after using CP4DMF (and KERMIT-80) to restore
;	the normal handling of XON/XOFF; the user may also elect to cold-boot
;	the DECMATE instead.
;
;	acknowledgments and limitations.
;
;	This program is based on DECMATE specific implementation details
;	provided by Walt Lamia of DEC. It is of course, specific to DECMATE
;	implementations of CP/M-80 for DECMATE II, III, III-plus, etc.
;
;	usage consists of merely:
;
;	CP4DMF			run xon/xoff disable program
;	KERMIT80		then run kermit
;	<KERMIT-80 commands used normally here, including SET IBM ON>
;	CP4DMU			run this program to restore normal XON
;
;	unless CP4DMU is run following KERMIT-80, the normal handling of
;	XON/XOFF provided by KERMIT-80 will not work (cold boot is another
;	alternative).
;
;	[Note - These edits now included in the init/de-init code]
;
; edit 38, 23 July, 1987 by OBSchou.  Moved out commonly used code 
;	to CPXCOM.ASM, and adjusted this (ond other family) files accordingly.
;	Also filtered out code now in other family files.
;
; edit 37 , 15 July 1987 by OBSchou for David Moore, who has submitted 
;	code for Teletek SYSTEMASTER (teletek) and for an ADM 22 terminal.
;
; edit 36 28 Jan 87 by OBSchou.
;	Removed the printx etc and should only have this file if a system
;	does not have a family file.
;
; edit 35 1st Dec 1986 by OBSchou.  Added test for Amstrad PCW range (PCW)
;	Links to CPXPCW.ASM, which was submitted by Ian Young, Lattice 
;	Logic Systems.
;
; edit 34 20 August by OBSchou for Brian Robertson, Aberdeen University:
;	I have discovered a bug in my code for the BBC/Z80 version of Kermit.  
;	At startup the transmitter baud rate is read from the serial ULA.  
;	The TX and RX baud rates are then reset to this value and the 
;	value is stored in location 'baud:' for the STATUS (or SHOW) 
;	command.  That is how it is supposed to work !	Unfortunately 
;	my code at present "misreads" the initial TX baud rate	- there 
;	is some bit manipulation that needs to be done to extract the 
;	correct value.
;
; edit 33 30-May-86 OBSchou.  Added two new enties to the overly.  One for 
;	printer status and the other for the address of the family of 
;	computer using the overlay.  If it is still in CPXSYS.ASM then it 
;	is a dollar only.
;
;edit 32, 27 May, 1986 by OBSchou Loughborough University for
;	B Robertson, Aberdeen Univ. Computing Centre. Any mistakes my fault.
;	Add support for APPLE II with serial cards based on the 6850 ACIA.
;	Mod 380Z support to allow both MDS (5 1/4" discs) and FDS (8" discs)
;	configurations.
;
; edit 31, 22 April, 1986, OBSchou.  
;	Kermit version 4.06 starts here. All previous edits have been 
;	put aside (leave in a BWR file?).  Hived off some definitions 
;	to the CPSDEF.ASM file as that is where they belong.  
;	Start on splitting off individual 
;	systems from this huge file.  It is done using the LINK facility 
;	LASM.  We link to a collection of systems under CPXxxx.ASM.
;	I have started with the systems I know, the Torch, Cifer and 
;	pci2651.  These will all be held under CPXTOR.ASM
;
;
; Keep module name, edit number, and last revision date in memory.
family:	db	'CPXSYS.ASM (40)  28-Aug-89 $'	; now a family...
;


; Processor speed in units of 100KHz
; for cpt85xx, advance, apple,bbc,px8 & rm380z timing loop [12]
IF rm380z 
cpuspd	SET	40		; 4.0 MHz CPU
ENDIF; rm380z 

IF disc	OR mmate OR s1008 OR access 
cpuspd	SET	40		; 4.0 MHz CPU
ENDIF	;disc OR mmate OR s1008 OR access 

IF bbc	;[9]
cpuspd	SET	60		; BBC with 6Mhz Z80
ENDIF;bbc


; the basics...

IF gener
batio	EQU	056H	;I/O byte CON=BAT,LIST=CRT,READER=RDR,PUNCH=PTP
defio	EQU	095H	;I/O byte CON=CRT,LIST=LPT,READER=RDR,PUNCH=PTP
crtio	equ	01010101B	; use CRT: device
ptrio	equ	01010110B	; use PTR: device
ttyio	equ	00000000B	; use TTY: device
uc1io	equ	01010111B	; use UC1: device
ur1io	equ	01101010B	; use UR1: device
ur2io	equ	01111110B	; use UR2: device
ENDIF;gener

IF robin
batio	EQU	056H	;I/O byte CON=BAT,LIST=CRT,READER=RDR,PUNCH=PTP
defio	EQU	095H	;I/O byte CON=CRT,LIST=LPT,READER=RDR,PUNCH=PTP
lptio	EQU	054H	;I/O byte CON=TTY,LIST=CRT,READER=PTR,PUNCH=PTP
gppio	EQU	057H	;I/O byte CON=UC1,LIST=CRT,READER=RDR,PUNCH=PTP
ENDIF;robin


IF dmII	OR bbc	;[22]
batio	EQU	042H	;I/O byte CON=BAT,LIST=CRT,READER=RDR
defio	EQU	081H	;I/O byte CON=CRT,LIST=LPT,READER=RDR
ENDIF;dmII

IF mikko
batio	EQU	10110010B ; I/O byte console => serial line
defio	EQU	10000001B ; I/O byte console => CRT and Keyboard
ENDIF;mikko
;
IF lobo	;[hh]
mnport	EQU	0F7E4H	;Modem data port A
mnprts	EQU	0F7E5H	;Modem status/conrtol port A
baudrt	EQU	0F7D0H	;Baud rate port A
output	EQU	04H	;Transmit buffer empty
input	EQU	01H	;Receive data available
z80	SET	TRUE	;a good z80, here
ENDIF;lobo

IF osi
mnport	EQU	0CF01H	;Modem data port
mnprts	EQU	0CF00H	;Modem status port
output	EQU	02H	;Transmitter empty
input	EQU	01H	;Input data available
z80	SET	FALSE	;I don't know...
ENDIF;osi

IF vector
mnport	EQU	04H	;Modem data port
mnprts	EQU	05H	;Modem status port
output	EQU	01H	;Transmitter empty
input	EQU	02H	;Input data available
z80	SET	FALSE	;I don't know...
ENDIF;vector

IF delphi		;[7]
mnport	EQU	22H	;[7] Modem data port
mnprts	EQU	23H	;[7] Modem status port
output	EQU	01H	;[7] Transmitter empty
input	EQU	02H	;[7] Input data available
baudrt	equ	29h	;[7] Baud rate port for channel 2 (default)
z80	SET	true	;[7] We're using the z80 side of the dual processor
ENDIF;[7] delphi

IF trs80
;NEEDS display definition (e.g. trs80lb or trs80pt)
mnport	EQU	0F4H	;Modem data port (0F5H for port B)
mnprts	EQU	0F6H	;Modem status port (0F7H for port B)
output	EQU	04H	;Transmitter empty
input	EQU	01H	;Input data available
z80	SET	TRUE	;[hh] All TRS-80's but the CoCo
ENDIF;trs80

IF teletek
mnport	EQU	00H	;Modem data port (02 for port B (console))
mnprts	EQU	01H	;Modem status port (03 for port B (console))
baudrt	EQU	08H	;ctc0 control port (09 for port B (console))
output	EQU	04H	;Transmitter empty
input	EQU	01H	;Input data available
z80	SET	TRUE	;All Teleteks
ENDIF;teletek

IF osbrn1
;Osborne 1 uses 6850 ACIA, but memory mapped.  Derived from Apple.
BAUDRT	EQU	0EFC1H	;Memory location where baud rates are stored.
OSTOP	EQU	4000H	;Where we move OSMOVE to at startup
OSPORT	EQU	2A01H	;Communications Port.
OSPRTS	EQU	2A00H	;Communications Port Status.
OUTPUT	EQU	02H	;Output Buffer Empty.
INPUT	EQU	01H	;Input Register Full.
OSBIN1	EQU	57H	;First Init Character for 6850 ACIA (Reset)
;(I would have thought 03, but prom code writes 57 there)
OSBI12	EQU	55H	;Second Init Character for ACIA (8-bits, 1200)
OSBI03	EQU	56H	;Second init char. for ACIA (8 bits, 300)
;(don't ask.. I don't know why SETUP writes 55 and 56 either)
z80	SET	TRUE	;[hh] a z80 here, also
ENDIF;osbrn1

IF robin
;Those definitions below that are commented out are just for information
;***** NOT generally found in distributed documentation ****

;pbausl EQU	90H	;The Baud-Rate register.
prntst	EQU	49H	;Printer
;prndat EQU	48H
contst	EQU	41H	;Console
;condat EQU	40H
gentst	EQU	51H	;General port.
;gendat EQU	50H
comtst	EQU	59H	;COMM-Port
;comdat EQU	58H
;output EQU	01H	;Output ready bit.
;input	EQU	02H	;Input ready bit.
z80	SET	TRUE	; This one's a Z80.
ENDIF;robin

IF s1008	;[29]
mnport	equ	00		;printer port data
mnprts	equ	01		;printer port status
output	equ	4		;transmitter ready
input	equ	2		;receiver ready
z80	equ	FALSE		;not important
ENDIF;s1008 [29]

IF mmate	;[29]
mnport	EQU	89H		;MODEM data port
mnprts	EQU	8BH		;MODEM status/control port
output	EQU	04H		;Transmit buffer empty, ready to send
input	EQU	01H		;Receive data available
baudrt	EQU	93H		;MODEM baud rate port
			;NOTE - also used for console
z80	SET	TRUE
ENDIF;mmate [29]

IF disc	;[29]
mnport	EQU	05		;Discovery 83U port B data
mnprts	EQU	04		;Discovery 83U port B status/command
output	EQU	04		;Transmit buffer empty
input	EQU	01		;Receiver ready
z80	SET	TRUE
ENDIF;disc [29]

IF cmemco		;[25]
tuart	EQU	020H	;TU-ART address
mnport	EQU	tuart+1	;Modem data port
mnprts	EQU	tuart	;Modem status port
output	EQU	080H	;Transmitter empty
input	EQU	040H	;Input data available
baudrt	EQU	tuart	;Baud rate port
;Note:	Needs terminal definition 
z80	SET	TRUE	;This one's a Z80.
ENDIF;cmemco

IF cpt85xx
baudrt	EQU	4Ch		; Baud rate generater (National MM5307)
mnport	EQU	4Bh		; Comm port data register (Intel 8251)
mnprts	EQU	4Ah		; Comm port command/status register
output	EQU	01h		; Transmitter buffer empty flag
input	EQU	02h		; Reciver buffer full flag
TxEmpty	EQU	04h		; Transmitter empty flag
z80	SET	FALSE		; It's really an 8080 [or 8085 ... same thing]
ENDIF;cpt85xx

IF mmdI	;Morrow MicroDecision - the single-board one
mnport	EQU	0FEH	;Morrow Printer UART data port
mnprts	EQU	0FFH	;Morrow Printer UART command/status
output	EQU	01H	;Output ready bit.
input	EQU	02H	;Input	ready bit.
;Note:	Needs terminal definition 
z80	SET	FALSE	;I don't know...
ENDIF;mmdI

IF bbc		;[22]
osbyte	EQU	0FFF4H	; OS entry point
osword	EQU	0FFF1H	; "    "     "
term	EQU	0FFC8H	;Terminal mode OS entry
z80	SET	TRUE
ENDIF;[22] bbc

;Two types of 380Z system
IF rm380zm		;[27] MDS - 5 1/4" discs
mnport	EQU	0C8H	;Modem data port
mnprts	EQU	0C9H	;Modem status port
ENDIF;[32] rm380zm

IF rm380zf	;[32] FDS - 8" discs
mnport	EQU	0E8H	;Modem data port
mnprts	EQU	0E9H	;Modem status port
ENDIF;[32] rm380zf

IF rm380z	;[32] Common to both systems
output	EQU	01H	;Transmitter buffer empty
input	EQU	02H	;Input data available
TxEmpty	EQU	04h	;Transmitter empty flag
z80	SET	TRUE
ENDIF;[22] rm380z

IF px8	; [29]
z80	SET	TRUE
mnprts	EQU	0dh	; used in sending a break
ENDIF	;px8 [29]

IF mdI	;Morrow Decision I - the big sucker
mnport	equ	48H		; Modem data port.
mnprts	equ	4DH		; Modem status port.
output	equ	20H		; Transmitter empty.
input	equ	1		; Input data available.
mbase	equ	48H		; Base address of Multi I/O port
				;   selector area.
grpsel	equ	4FH		; Group select port.
rbr	equ	48H		; Read Data Buffer.
group	equ	1		; Multi I/O Group byte for serial ports.
congrp	equ	1		; Serial Port 1 for console
mdmgrp	equ	3		; Serial Port 3 for modem.

; Following are needed for baud rate changes...[Toad Hall]

dlm	equ	49H		; Baud Rate Divisor (Most Sig Bit)
dll	equ	48H		; Baud Rate Divisor (Least Sig Bit)
ier	equ	49H		; Interrupt Enable Register
lcr	equ	4BH		; Line Control Register
lsr	equ	4DH		; Line Status Register
msr	equ	4EH		; Modem Status Register
dlab	equ	80H		; Divisor Latch Access Bit
wls0	equ	1		; Word Length Select Bit 0
wls1	equ	2		; Word Length Select Bit 1 for 8 bit word
stb	equ	4		; Stop bit count - 2 stop bits
imask	equ	0		; Interrupt mask (all disabled)
z80	SET	TRUE		; This one's a Z80.
ENDIF	;mdI   NOTE: needs terminal definition. [Toad Hall]

IF mikko
sioac	EQU	0FF12H		;SIO channel A register(s) address
sioo3	EQU	01000001B	;SIO Write Reg. 3 original setup (?)
				;RX 7 bits,synch mode bits 0,RX enable
sion3	EQU	11001111B	;SIO Write Reg. 3 KERMIT setup
				;RX 8 bits,synch mode bits 0,RX enable
sioo4	EQU	01001111B	;SIO Write Reg. 4 original setup (?)
				;X16 clock,8 bit synch(ignored),
				;2stop bits,par even(on)
sion4	EQU	01000100B	;SIO Write Reg. 4 KERMIT setup
				;X16 clock,8 bit synch(ignored),
				;1stop bit,par off
sioo5	EQU	10101010B	;SIO Write Reg. 5 original setup (?)
				;DTR,TX 7 bits,TX enable,RTS
sion5	EQU	11101010B	;SIO Write Reg. 5 KERMIT setup
				;DTR,TX 8 bits,TX enable,RTS
txclk	EQU	0FF30H	;Baud rate generator (CTC) for transmitter
rxclk	EQU	0FF31H	;Baud rate generator (CTC) for receiver
chmask	EQU	0F1F2H	;Mask byte address for SIO ch. A reception
z80	SET	TRUE	;It's got a SIO and a CTC, it must be a Z80
ENDIF;mikko


IF access	;[29]
mnport	EQU	40H	;Modem data port A
mnprts	EQU	42H	;Modem status/conrtol port A
output	EQU	04H	;Transmit buffer empty
input	EQU	01H	;Receive data available
z80	SET	TRUE	;a good z80, here
ENDIF;access [29]


IF robin OR dmII
z80	SET	TRUE	; This one's a Z80
ENDIF;robin OR dmII

IF hp125			;[MF]
z80	SET	TRUE		;HP-125 uses a Z80
ENDIF;hp125 [MF]

IF gener OR cpm3	; To be truly generic, we must assume 8080.
z80	SET	FALSE
ENDIF;gener OR cpm3
;
IF osi
defesc	EQU	']'-100O	;The default escape character.
ENDIF; osi 

IF vector
defesc	EQU	'~'		;Vector can't type ']'.
ENDIF;vector

IF mikko OR osbrn1 OR lobo
defesc	EQU	'\'-100O	;The default is Control \ -- it's easier B.E.
ENDIF;mikko OR osbrn1 OR lobo

IF cpt85xx
defesc	EQU	'\'-100O	;Still Control-\ (just ran out of room...)
ENDIF;cpt85xx

IF bbc OR rm380z OR px8 OR access OR S1008	;[22] [29]
defesc	EQU	'\'-100O	;Still Control-\ (just ran out of room...)
ENDIF	;bbc OR rm380z OR px8 OR access OR s1008[29]

IF trs80
defesc	EQU	'_'-100O	;CTRL-_ (Down-arrow on TRS-80 keyboard)
ENDIF;trs80

; Select initial setting for VT-52 emulation flag.

IF vt52 ; If console looks like (or is) VT52
vtval	EQU	0		;  we don't need VT52 emulation
ENDIF;vt52

; If none of the above, default to VT52-EMULATION ON.
IF NOT (crt OR vt52 OR robin OR dmII OR vt100 OR hp125);[MF]
vtval	EQU	1
ENDIF;NOT (crt OR vt52 OR robin OR dmII OR vt100 OR hp125)[MF]


;	sysxin	- system dependent initialisation code, called from SYSINIT
;
sysxin:

IF dmII
; edit added by OBSchou for C. Lasner.	If this dont work, tell me whats
;	wrong, as I have no DMII or IBM to play with
;
;	IBM mode fixup program
;
;	This routine must be run before attempting to use KERMIT-80 with half
;	duplex KERMIT implementations such as CMS-KERMIT, as the 6120 processor
;	will otherwise "swallow" the XON character.
;
;	acknowledgments and limitations.
;
;	This program is based on DECMATE specific implementation details
;	provided by Walt Lamia of DEC. It is of course, specific to DECMATE
;	implementations of CP/M-80 for DECMATE II, III, III-plus, etc.
;
;	usage consists of merely:
;
;	CP4DMF			run this program
;	KERMIT80		then run kermit
;	<KERMIT-80 commands used normally here, including SET IBM ON>
;	CP4DMU			run companion program to restore normal XON
;
;	unless CP4DMU is run following KERMIT-80, the normal handling of
;	XON/XOFF provided by KERMIT-80 will not work (cold boot is another
;	alternative).
;
;	CP4DMF.ASM
;
;	last edit:	12-jun-87	20:00:00	Charles J. Lasner (CJL)

;oboff	equ	3fh		; offset of outbyt routine for 6120
;prtctl	equ	02h		; port control
nocoxon	equ	001h		; turn off comm. output XON

	lxi	b,(nocoxon * 100h) + prtctl ; c/prtctl, b/no out. xon
	call	outbyt
	ret			; and return

;outbyt has been catered for (in break routine)
ENDIF	;dmII

IF osbrn1	;(Note now no longer needs code > 4000h as it is already there
;	lxi	d,ostop		;where we're moving it to
;	lxi	h,osmove	;what we're moving
;	mvi	b,osmct		;How many bytes we're moving
;	call	mover
	lda	baudrt		; Find out what speed is current
	ani	1
	mvi	a,osbi03	; assume 300 baud
	jz	osstr1
	mvi	a,osbi12	; nope, it's 1200.
osstr1:	sta	speed		; save initial speed
	sta	speed+1		;  as 16 bits, to match speed table entries
	mov	d,a
	mov	e,a		; get initial speed in DE
	call	sysspd		;set up parity etc.
ENDIF;osbrn1

IF cpt85xx
	mvi	a,80h		; Send UART reset [force idle] by setting
	out	baudrt		;    bit 7 of baud rate I/O port
	lxi	H,0f0fh		; Clear reset and default to 9600 baud [23]
	shld	speed		; store current speed
	xchg
	call	sysspd		; set default baud rate
	mvi	a,4Eh		; Set UART mode to async 16x clock, 8 data
	out	mnprts		;    bits, no parity, and 1 stop bit
	mvi	a,37h		; Set command to Tx enable, DTR on, Rx enable,
	out	mnprts		;    break off, error reset, and RTS on
ENDIF	; cpt85x

IF bbc		;[22]
	lxi	d,modstr	; Set MODE 3
	call	prtstr
	mvi	a,1		; Set terminal mode on
	call	term
	mvi	a,0F2H		; Read current transmit speed
	lxi	h,0FF00H	; .. 3 lsb of ULA register
	call	osbyte		;   FX242,0,255
	mov	a,l
	ani	7		; Mask of 3 lsb
;
; Edit of July 22, 1986 by B Robertson, Aberdeen Univ. Computing Centre.
; Correct bug in sysinit for BBC  -  reads the initial baud rate at
; start up incorrectly.
;
;
	rar			; Reverse order of 3 lsb
	rar			; Bit2 now in bit0
	jnc	binit1		;
	ori	2		; Restore bit1
binit1:	ana	a		; Set sign bit as appropriate
	jp	binit2		;
	ori	4		; Bit0 now in bit2
binit2:	ani	7		; Mask off unwanted bits
; End of Edit

	xri	7		; Stored as 2's complement
	inr	a
	sta	speed		; Store 16 bit value
	sta	speed+1
	mov	e,a		; Ensure RX and TX speeds are the same
	call	sysspd
ENDIF;[22] bbc

IF rm380z	;[22]
	mvi	e,11h		;Output ctrl-Q to clear autopaging
	call	outcon
ENDIF;[22] rm380z


IF lobo	;[hh]
	lxi	d,siotbl	;[hh] address of status table
	mvi	c,siolen	;[hh] length of the table
siolup:	;[hh] loop here for each command byte
	ldax	d		;[hh] load first byte into A
	inx	d		;[hh] index pointer to next bute
	sta	mnprts		;[hh] send it to status port A
	sta	mnprts+2	;[hh] and to status port B
	dcr	c		;[hh] decrement the counter
	jnz	siolup		;[hh] loop back for more commands
	mvi	a,05H		;[hh] value for 300 baud
	sta	baudrt		;[hh] starting default for port A
	sta	baudrt+4	;[hh] and for port B
	sta	speed		;[hh] tell program they're set
	mvi	a,0E4H		;[hh] value for port A
	sta	port		;[hh] tell program we've set this, too
	mvi	a,0D0H		;[hh] port A baud rate value
	sta	port+1		;[hh] save this as well, for consistancy
ENDIF	;lobo

IF mikko
	lxi	d,mintbl	;Address of KERMIT Reg values (what)
	mvi	c,minlen	;Length of table (how many)
	lxi	h,sioac		;Send data to ch. A SIO registers (to where)
	call	movmik
	mvi	a,0FFH		;Set ch. A mask to use all bits
	sta	chmask
ENDIF;mikko

IF mdI
	lxi	h,96		;Default 1200 baud modem port speed
	shld	speed		;Store as modem port speed
	call	sysspd		;Initialize the port
ENDIF;mdI  [Toad Hall]

IF cmemco			;[25]
	mvi	a,01h		; Reset TU-ART
	out	tuart+2
	mvi	a,90h		; Set default baud rate (2400), and 1 stop bit
	out	tuart
	sta	speed		; save for status display
	sta	speed+1
ENDIF;cmemco

IF delphi			;[7]
;
;	shove the default baud rate (1200) in to the Delphi port address
;	for the baud rate generator on port 2, the default port; save this
;	value so we can tell what speed is selected.
;
	mvi	a,07h		;[7] get value for 1200 baud
	out	baudrt		;[7] set it for port 2
	sta	speed		;[7] save for status display
	sta	speed+1
ENDIF;[7] delphi

IF px8 ; [29]
	lda	0f6a9h		; get baud rate value set by CONFIG
	sta	px8blk+4	; put into parameter block
	mov	h, a		; initialise global speed indicator
	mov	l, a
	shld	speed
	lhld	6		; base of CP/M
; buffer starts at ovlend+8192, immediately after sector buffer
; We must also allow (800h) for the CCP as Kermit exits with a RET
	lxi	d, ovlend+8192+800h  ; calc buffer length
	ora	a		; clear carry
	db	0edh, 52h	; sbc hl, de
	shld	px8blk+2
	call	rsopen
ENDIF ; px8 [29]

IF disc	;[29]
;Initialization sequence for Discovery 83U port B
;Sets port to 9600 baud, 8 data bits, 1 stop bit, no parity
	mvi	a,12		;Register 12
	out	mnprts
	mvi	a,11		;Low byte of time constant for 9600
	out	mnprts
	mvi	a,13		;Register 13
	out	mnprts
	mvi	a,0		;High byte of time constant for 9600
	out	mnprts
	mvi	a,14		;Register 14
	out	mnprts
	mvi	a,3		;Enable baud rate generator
	out	mnprts
	mvi	a,11		;Register 11
	out	mnprts
	mvi	a,52h		;No Xtal, tclk=rclk=/trxc out=br gen
	out	mnprts
	mvi	a,4		;Register 4
	out	mnprts
	mvi	a,44h		;16x clock, 1 stop, no parity
	out	mnprts
	mvi	a,3		;Register 3
	out	mnprts
	mvi	a,71h		;rx 8 bit/ch, autoenable, rx enable
	out	mnprts
	mvi	a,5		;Register 5
	out	mnprts
	mvi	a,0eah		;tx 8 bit/ch, tx enable, rts
	out	mnprts
ENDIF;disc [29]
;
;
IF mikko			;currently for MIKROMIKKO only
; copy command block into memory-mapped SIO.
movmik:	di			;disable interrupts
movmk1:	ldax	d		;Get a register value
	mov	m,a		;Output it
	inx	d		;Next value
	dcr	c		;Decrement counter
	jnz	movmk1		;Repeat until done
	ei
	ret
ENDIF;mikko

;
IF osbrn1
osmove:
osflag	equ	0EF08H		;Osborne 1 Bank-2 flag
;
; return modem status in A
;
OSLDST:
	DI
	OUT	0
	LDA	osprts		;Read the status port
	OUT	1
	EI
	ret
;
; set modem status from A
;
OSSTST:
	DI
	OUT	0
	STA	osprts	;Write the control port
	jmp	osstex
;
; read character from modem into A
;
OSLDDA:
	DI
	OUT	0
	LDA	osport
	OUT	1
	EI
	ret
;
;	output character in A to modem
;
OSSTDA:
	DI
	OUT	0
	STA	osport
osstex:
	OUT	1
	mvi	a,1
	sta	osflag
	EI
	ret
ENDIF;osbrn1

IF lobo
; List of commands to set up SIO channel A for asynchronous operation.
siotbl:	DB	18H		; Channel reset
	DB	18H		; another, in case register 0 wasn't selected
	DB	04H		; Select register 4
	DB	44H		; 1 stop bit, clock*16
	DB	01H		; Select register 1
	DB	00H		; No interrupts enabled
	DB	03H		; Select register 3
	DB	0C1H		; Rx enable, 8 bit Rx character
	DB	05H		; Select register 5
	DB	0EAH		; Tx enable, 8 bit Tx character,
				;  raise DTR and RTS
siolen	equ	$-siotbl	; length of command list
ENDIF;lobo

IF mikko
; command list to set SIO chip back to normal state
miotbl:	db	3		;reg. 3
	db	sioo3
	db	5		;reg. 5
	db	sioo5
	db	4		;reg. 4
	db	sioo4
	db	0		;reselect reg. 0
miolen	equ	$-miotbl	;MikroMikko SIO table length (original values)

; command list to set up SIO chip for operation with Kermit
mintbl:	db	3		;reg. 3
	db	sion3
	db	5		;reg. 5
	db	sion5
	db	4		;reg. 4
	db	sion4
	db	0		;reselect reg. 0
minlen	equ	$-mintbl	;MikroMikko SIO table length (KERMIT values)
ENDIF;mikko


IF bbc		;[22]
modstr:	db	16h,03h,'$'	; String to put screen into MODE 3
ENDIF

IF px8 ; [29]
rsget:	mvi	b, 50h
	jmp	rsiox
rsinst:	mvi	b, 30h
	jmp	rsiox
rsput:	mvi	b, 60h
	jmp	rsiox
rsoutst:mvi	b, 40h
	jmp	rsiox
rserst:	mvi	b, 90h
	jmp	rsiox
rsopen:	lxi	h, px8blk	; copy px8blk to px8prm
	lxi	d, px8prm
	lxi	b, 9
	call	mover
	mvi	b, 10h		; open code
	jmp	rsiox
rsclose:mvi	b, 20h		; close code
rsiox:	lxi	h, px8prm
	lxi	d, 51h		; offset into BIOS jump table
	push	h
	lhld	1		; start of BIOS
	dad	d
	xthl			; entry point on stack, px8prm addr in hl
	ret			; jump indirect

px8prm:	dw	0, 0
	db	0, 0, 0, 0, 0	; the param area is overwritten in rsopen
px8blk:	dw	ovlend+8192	; buffer address
	dw	0		; buffer size - overwritten
	db	0		; baud rate - overwritten
	db	3		; 8 bits/char
	db	0		; no parity, it is done internally
	db	1		; 1 stop bit
	db	0cfh		; special bits - activate xon/xoff
; The documentation suggests that the xon/xoff bit is bit 4, i.e the pattern
; should be 0efh, but the top bit is omitted from the diagram. I will try
; clearing both bit 4 and bit 5.
ENDIF ; px8 [29]

IF hp125			;[MF]
	lxi	b,73ffh		;Prepare Data Comm 1 to
	call	bdos		;Transfer eight-bit data
	lxi	d,jbuf		;Point to bios jump-table vector
	lxi	b,7effh		;Set up special subfunction code to
	call	bdos		;Get rdr routine address
	lhld	jbuf+3		;Remember this address
	shld	readin+1	;for our eight-bit rdr routine
	mvi	a,1		;We want to write into the bios jump table
	sta	jbuf+1		;...
	lxi	h,readin	;Point to our rdr routine (all 8 bits)
	shld	jbuf+3		;as new RDR routine
	lxi	d,jbuf		;Point to jump vector argument block
	lxi	b,7effh		;Set subfunction code to
	call	bdos		;Substitute our rdr routine in dispatch table
	lxi	h,mapon1	;Make Data Comm 1 the default port
	shld	port		;at program-start
	xchg			;Put in DE
	call	prtstr		;Print escape sequences to connect
				;DAta Comm 1 to rdr/punch
ENDIF ;hp125 [MF]

	ret			; end of sysxin

;
;	system-dependent termination processing
;	If we've changed anything, this is our last chance to put it back.
sysexit:

IF dmII
; Edited by OBSchou for Charles Lasner.	 His bug fix now in Kermit-80:
;
;	IBM mode restore program
;
;	This routine must be run after using CP4DMF (and KERMIT-80) to restore
;	the normal handling of XON/XOFF; the user may also elect to cold-boot
;	the DECMATE instead.
;
;	acknowledgments and limitations.
;
;	This program is based on DECMATE specific implementation details
;	provided by Walt Lamia of DEC. It is of course, specific to DECMATE
;	implementations of CP/M-80 for DECMATE II, III, III-plus, etc.
;
;	usage consists of merely:
;
;	CP4DMF			run xon/xoff disable program
;	KERMIT80		then run kermit
;	<KERMIT-80 commands used normally here, including SET IBM ON>
;	CP4DMU			run this program to restore normal XON
;
;	unless CP4DMU is run following KERMIT-80, the normal handling of
;	XON/XOFF provided by KERMIT-80 will not work (cold boot is another
;	alternative).
;
;	CP4DMF.ASM
;
;	last edit:	12-jun-87	20:00:00	Charles J. Lasner (CJL)
;
coxon	equ	000h		; enable comm. output XON
;oboff	equ	3fh		; offset of outbyt routine for 6120
;prtctl	equ	02h		; port control


	lxi	b,(coxon * 100h) + prtctl ; c/prtctl, b/with out. xon
	call	outbyt		;[OBS] declared elswhere
	ret			; and return

ENDIF	;dmII

IF mikko
	lxi	d,miotbl	;Load the adress of original reg values
	mvi	c,miolen	;Length of table
	lxi	h,sioac		;Send data to ch A SIO registers
	call	movmik
	mvi	a,07FH		;Set ch A mask to use just 7 bits
	sta	chmask
ENDIF;mikko

IF teletek
;Note - This code was handwritten onto the lising I was sent, with the 
;	comment that David had just thought of the code, so it was 
;	not on the listing. If you have problems I suggest you 
;	comment out these few lines.
;Bertil Schou.
;
	di
	mvi	a,47h		; reset baud rate to 9600
	out	baudrt
	mvi	a,08h
	out	baudrt
	ei
ENDIF	;teletek

IF cpt85xx
	mvi	a,80h		; Reset (force idle) the 8251 UART via bit 7
	out	baudrt		;    of the baud rate generater port
	mvi	a,00h		; and turn off the baud rate generater
	out	baudrt
ENDIF;cpt85xx

IF bbc	;[22]
	mvi	a,0		; Turn off terminal mode
	call	term
ENDIF;[22] bbc

IF px8	;[29]
	call	rsclose
ENDIF	;px8 [29]

IF hp125			;[MF]
	lxi	b,74ffh		;Set subfunction code to
	call	bdos		;Reset Data Comm 1 for 7-bit data
	lhld	readin+1	;Get original rdr routine address
	shld	jbuf+3		;and store in jump vector
	lxi	d,jbuf		;Point to jump vector
	lxi	b,7effh		;Set subfunction code to
	call	bdos		;Put original rdr routine back in bios
				;dispatch table
	lxi	d,mapoff	;Point to escape sequences to
	call	prtstr		;Turn off Data Comm 1/2 mappings
ENDIF ;hp125 [MF]

	ret

;
;	system-dependent processing for start of CONNECT command
;
syscon:
IF robin OR trs80 OR cpt85xx	;For Robin/TRS80/CPT-85xx, add some more info
	lxi	d,conmsg	; about obscure key combinations
	call	prtstr
ENDIF;robin OR trs80 OR cpt85xx

IF osbrn1			;*** This is Software dependent ***
	lhld	1		;Modify back-arrow code to DELETE
	mvi	l,0		;Get BIOS-start address
	lxi	d,85H		;Adress for key-code = XX85H
	dad	d
	mov	e,m		;Get it in DE
	inx	h
	mov	d,m
	xchg			;Memory pointer to HL
	mvi	m,del		;modify the code
ENDIF;osbrn1
	ret

conmsg:		; Messages printed when entering transparent (CONNECT) mode:
IF robin	;  for Robin, control-S key is hidden
	db	' (Type Left Arrow to send CTRL-S)',cr,lf,'$'
ENDIF;robin
IF trs80	;  for TRS-80, the preferred escape key is hidden
	db	' (Control-_ is the Down-Arrow key on the TRS-80 keyboard)'
	db	cr,lf,'$'
ENDIF;trs80
IF cpt85xx	;  for CPT-85xx, some graphics map "funny" to keyboard in CP/M
	db	' (Use	CODE + SHIFT + 1/2  key to generate a Control-\)'
	db	cr,lf,'$'
ENDIF;cpt85xx
;
;	syscls - system-dependent close routine
;	called when exiting transparent session.
;
syscls:
IF osbrn1
	lhld	1		;Modify back-arrow code to BACKSPACE
	mvi	l,0		;Get BIOS address
	lxi	d,85H		;Address for key-code =XX85H
	dad	d
	mov	e,m		;Get it in DE
	inx	h
	mov	d,m
	xchg			;Address to HL
	mvi	m,bs		;Modify code
ENDIF;osbrn1
	ret
;
;	sysinh - help for system-dependent special functions.
;	called in response to <escape>?, after listing all the
;	system-independent escape sequences.
;
sysinh:
IF robin OR dmII OR cpt85xx OR lobo 
	lxi	d,inhlps	; we got options...
	call	prtstr		; print them.
ENDIF;robin OR dmII OR cpt85xx OR lobo 

IF bbc OR rm380z ; some more
	lxi	d,inhlps	; we got options...
	call	prtstr		; print them.
ENDIF;[22] bbc OR rm380z 

IF px8 OR access OR mmate OR disc ;and more...
	lxi	d,inhlps	; we got options...
	call	prtstr		; print them.
ENDIF	;px8 OR access OR mmate OR disc 

	ret


;additional, system-dependent help for transparent mode
; (two-character escape sequences)
inhlps:

IF robin OR dmII OR cpt85xx OR lobo
	db	cr,lf,'B  Transmit a BREAK'
ENDIF;robin OR dmII OR cpt85xx OR lobo 

IF bbc OR rm380z 
	db	cr,lf,'B  Transmit a BREAK'
ENDIF;bbc OR rm380z 

IF px8 OR access OR mmate 
	db	cr,lf,'B  Transmit a BREAK'
ENDIF	;px8 OR access OR mmate 

IF disc	;[29] [32]
	db	cr,lf,'B Transmit a 300ms BREAK'
	db	cr,lf,'L Transmit a 5 second BREAK'
ENDIF;disc [29]

IF lobo
	db	cr,lf,'D  Drop the line'
ENDIF;lobo

	db	'$'			;[hh] table terminator

;
;	sysint - system dependent special functions
;	called when transparent escape character has been typed;
;	the second character of the sequence is in A (and in B).
;	returns:
;	non-skip: sequence has been processed
;	skip:	sequence was not recognized

sysint:	ani	137O		; convert lower case to upper, for testing...

IF robin OR dmII OR cpt85xx OR lobo 
	cpi	'B'		; send break?
	jz	sendbr		; yes, go do it.  return nonskip when through.
ENDIF;robin OR dmII OR cpt85xx OR lobo 

IF bbc OR rm380z ; [22] [25] ... some more
	cpi	'B'		; send break?
	jz	sendbr		; yes, go do it.  return nonskip when through.
ENDIF; bbc OR rm380z 

IF px8 OR access OR	mmate ;[28] [29] and anothers
	cpi	'B'		; send break?
	jz	sendbr		; yes, go do it.  return nonskip when through.
ENDIF	; px8 OR access OR mmate [28] [29]

IF lobo	;[hh]
	cpi	'D'		;[hh] disconnect?
	jz	discon		;[hh] yes, go do it. nonskip return when done.
ENDIF	;lobo

IF disc	;[29]
	cpi	'B'		;Send short break?
	jz	sendbr
	cpi	'L'		;Send long break?
	jz	sendlbr
ENDIF;disc [29]

	jmp	rskp		; take skip return - command not recognized.


;
IF robin ;Definitions & code to send a BREAK (ungenerically, no other way).

comctl	equ	59h		;VT180 communications port
crtctl	equ	41h		;VT180 crt port

;VT180 serial port command bits

txe	equ	1		;transmit enable
dtr	equ	2		;dtr on
rxe	equ	4		;rx enable
sndbrk	equ	8
rerr	equ	10h		;reset error
rts	equ	20h		;RTS on
reset	equ	40h		;port reset

;Send a break to the communications port.
;

sendbr:	lxi	h,38500		;250 ms(?)
	lda	prtadr		;Get address of selected port
	mov	c,a		;Into C
	mvi	a,sndbrk+dtr
;	OUT	C,A		;Want to send to port addressed by C
	db	0EDH,079H	;Op code for above instruction
sndbr1:	dcx	h		;timing loop...
	mov	a,l
	ora	h
	jnz	sndbr1		;...until over
	lda	prtadr		;Get the address for the port
	mov	c,a		;Into C
	mvi	a,txe+dtr+rxe+rerr+rts	;enable tr/rc, dtr, reset error
;	out	c,a		;Z-80 only instruction
	db	0EDH,079H	;Op code for above instruction
	out	contst		;reset ports
	ret
ENDIF;robin
;
IF dmII				;[jd] this added to send break on DECmate

; DECmate command codes for 6120 I/O processor
oboff	equ	3fh		; offset of outbyt routine for 6120
prtctl	equ	02h		; port control
brdat	equ	06h		; data to tell 6120 to send a break
brdur	equ	30		; duration, 30 = 300 ms.

sendbr:	lxi	b,(brdat * 100h) + prtctl ; c/prtctl, b/brdat
	call	outbyt
	lxi	b,brdur*100h		; b/duration, c/0
;	fall through into outbyt

outbyt:	lhld	1		; get warm boot address
	lxi	d,oboff		; offset of outbyt routine
	dad	d		; compute address
	pchl			; branch there (a callret)

ENDIF;dmII
;
IF access OR mmate ;[cjc] send break on Kaypro [29]
; Officially, a "break" is 300 milliseconds of "space" (idle line is
; "mark").  (or maybe 200 milliseconds; I forget.)  The timing isn't
; usually that critical, but we'll make an attempt, at least.  Sending
; too long a break can cause some modems to hang up.

sendbr:
;	First, make sure the transmitter is really empty.  (The SIO sets
;	"transmitter buffer empty" when it can accept another character;
;	the previous character is still being shifted onto the line.
;	Another status bit, "all done", is set to indicate that the
;	transmitter is really idle.
sndbr1:	mvi	a,1		; select Read Register 1
	out	mnprts
	in	mnprts		; read the contents
	ani	1		; test "all done" flag
	jz	sndbr1		; loop until it's nonzero.
;
;	Next, set the "send break" bit to start the transmitter spacing.
	mvi	a,5		; select Write Register 5
	out	mnprts
	mvi	a,0FAH		; Tx enable, 8 bit Tx character, Send Break,
	out	mnprts		;  DTR and RTS on.
;
;	Now, delay for 30 hundredths of a second
	mvi	a,30		; delay count
	call	delay
;
;	Time's up. Put transmitter back in normal state (data byte is the
;	same as the one in siotbl: for Write Register 5) and return.
	mvi	a,5		; select Write Register 5
	out	mnprts
	mvi	a,0EAH		; Tx enable, 8 bit Tx character,
	out	mnprts		;  DTR and RTS on.
	ret			; done.
ENDIF;access OR mmate [29]

IF lobo	;[hh]	This routine sends a break tone or disconnects a modem
;		(those that respond to it) by setting the DTR line low
;		for 300 ms.
;
sendbr:	mvi	a,05H		;[hh] write register 5
	call	outctl		;[hh] send it to control port
	mvi	a,0FAH		;[hh] value to send break tone
	jmp	sndbr1		;[hh]
;
discon:	mvi	a,05H		;[hh] write register 5
	call	outctl		;[hh] send it to the control port
	mvi	a,06AH		;[hh] DTR off and break tone on
sndbr1:	call	outctl		;[hh] send to control port
	mvi	a,30		;[hh] delay count for 300 ms.
	call	delay		;[hh] wait a while...
	mvi	a,05H		;[hh] write register 5
	call	outctl		;[hh] get it's attention
	mvi	a,0EAH		;[hh] normal 8 bits, DTR on, RTS on, etc.
	call	outctl		;[hh] restore SIO
	ret
;
outctl:	sta	mnprts		;[hh]
	ret
ENDIF	;lobo
;
IF cpt85xx OR rm380z ;[lmj] [22] [25]
sendbr:
;
;	Ensure that the transmitter has finished sending buffered chars
sndbr1:	in	mnprts		; get UART status
	ani	TxEmpty		; everything sent?
	jz	sndbr1		; no, wait a bit more
;
;	Begin sending a break by setting bit in UART command register
	mvi	a,3Fh		; Set TxEna, DTR, RxEna, SBreak, ErrRst, RTS
	out	mnprts
;
;	Wait for 250 milliseconds (using hundredths second delay routine)
	mvi	a,25
	call	delay
;
;	Resume normal operation by clearing the SendBreak command bit
	mvi	a,37h		;Set TxEna, DTR, RxEna, ErrRst, RTS
	out	mnprts
;
	ret			;done
ENDIF;cpt85xx OR rm380z 

IF px8 ; [29]
sendbr:	mvi	a, 3fh	; set break bit
	out	mnprts
	mvi	a, 25
	call	delay	; wait 250 msec
	mvi	a, 37h	; clear break bit
	out	mnprts
	ret
ENDIF ; px8 [29]

;
IF bbc		;[22]
sendbr:
;
;	Ensure that the transmitter has finished sending buffered chars
sndbr1:	mvi	a,96h		; get ACIA status
	mvi	l,8
	call	osbyte		; *FX150,8
	mov	a,h
	ani	2		; everything sent?
	jz	sndbr1		; no, wait a bit more
;
;	Disable centisecond clock (system VIA) which interferes with break
	lxi	h,0FE4Eh	; system VIA interrupt enable register
	mvi	a,40H		; disable timer 1
	call	wrtiom		; write to I/O processor memory
;
;	Begin sending a break by setting bit in ACIA control register
	mvi	a,9Ch
	lxi	h,9F60h		; Set Rxint, Txint, Break, RTS
	call	osbyte		; *FX 156,96,159
;
;	Wait for 250 milliseconds (using hundredths second delay routine)
	mvi	a,25
	call	delay
;
;	Resume normal operation by returning old control byte
	mvi	a,9Ch
	mvi	h,0		;Set TxEna, DTR, RxEna, ErrRst, RTS
	call	osbyte		; *FX 156,oldvalue,0
;
;	Enable centisecond clock (system VIA)
	lxi	h,0FE4Eh	; system VIA interrupt enable register
	mvi	a,0C0H		; enable timer 1
	call	wrtiom		; write to I/O processor memory
;
	ret			;done
;
;	Routine to write byte in A to I/O processor memory address
;	given by HL
wrtiom:
	shld	parblk		; store address to parameter block
	sta	parblk+4	; store data
	lxi	h,parblk	; load hl with address of param block
	mvi	a,6		; write I/O processor memory
	call	osword		; go do it
	ret
;
parblk:	DS	5		; reserve space for parameter block
ENDIF;bbc [22]
;
IF disc	;[29]
; This is almost an exact copy of the bbI sendbr routine.
; Modifications to include a long break have been made.
;
; Officially, a "break" is 300 milliseconds of "space" (idle line is
; "mark").  (or maybe 200 milliseconds; I forget.)  The timing isn't
; usually that critical, but we'll make an attempt, at least.  Sending
; too long a break can cause some modems to hang up.

sendlbr:
	push	d	;save d, this may not be necessary, but safe
	mvi	d,17	;do short break 17 times (approx. 5 sec.)
	jmp	sndbr1
sendbr:
	push d
	mvi	d,1	;On short break, do only once
; First, make sure the transmitter is really empty.  (The SIO sets
; "transmitter buffer empty" when it can accept another character;
; the previous character is still being shifted onto the line.
; Another status bit, "all done", is set to indicate that the
; transmitter is really idle.
sndbr1:	mvi	a,1		; select Read Register 1
	out	mnprts
	in	mnprts		; read the contents
	ani	1		; test "all done" flag
	jz	sndbr1		; loop until it's nonzero.
;
; Next, set the "send break" bit to start the transmitter spacing.
	mvi	a,5		; select Write Register 5
	out	mnprts
	mvi	a,0FAH		; Tx enable, 8 bit Tx character, Send Break,
	out	mnprts		;  DTR and RTS on.
;
; Now, delay for 30*d hundredths of a second
sendbr2:
	mvi	a,30		; delay count
	call	delay
; The following has been added to allow doing .03 delay d times
	dcr	d		; decrement # of times to do loop
	jnz	sendbr2		; if not done, do again
	pop	d		; reload d
;
; Time's up. Put transmitter back in normal state (data byte is the
; same as the one in siotbl: for Write Register 5) and return.
	mvi	a,5		; select Write Register 5
	out	mnprts
	mvi	a,0EAH		; Tx enable, 8 bit Tx character,
	out	mnprts		;  DTR and RTS on.
	ret			; done.
ENDIF	;disc [29]


;
;	sysflt - system-dependent filter
;	called with character in E.
;	if this character should not be printed, return with A = zero.
;	preserves bc, de, hl.
;	note: <xon>,<xoff>,<del>, and <nul> are always discarded.
sysflt:
	mov	a,e		; get character for testing
IF mikko
	cpi	'O'-100O	;Control-O's lock keyboard
	rnz			; if not control-O, it's ok.
	xra	a		; don't allow control-O out.
ENDIF;mikko

	ret

;	mdmflt - modem filter [30]
;	called with character to be sent to printer in E
;	with parity set as appropriate.
;	return with accumulator = 0 do do nothing,
;				<> 0 to send char in E.
mdmflt:
	mov	a,e		;[30] get character to test
	ret



;	prtflt - printer filter [30]
;	called with character to be sent to printer in E
;	returns with a = 0 to do nothing
;		     a <> 0 to print it.
;
;	this routine for those printer that automatically insert
;	a lf on cr, or cr for lf.  Should this be shifted to 
;	the system indep. stuff, in say 4.06?
prtflt:
	mov	a,e		; [30] get character to test
	ret


;
; system-dependent processing for BYE command.
;  for lobo, hang up the phone.
sysbye:
IF lobo ;[hh]
	call	discon		;[hh] force modem to hang up
ENDIF;lobo
	ret

IF lasm
	LINK	CPXSY2.ASM	; If m80 then this ignored
ENDIF	; lasm
