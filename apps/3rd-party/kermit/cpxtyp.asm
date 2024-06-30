; CPXTYP.ASM
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
;       This is the header file for building the system-dependent overlay
;       for KERMIT.  It contains the definitions used to select the target
;       system, and collects (via INCLUDE or LINK directives) the remaining
;       code.  If the target system is one of the supported systems
;       described below, then this is the only file that needs to be
;       edited.
;
; revision history:
;
;edit 34, 10-Jan-1991 by MF. Put in "terminal required" notation for
;	more machines that need terminals.
;edit 33, 9-Jan-1991 by MF. Put in "terminal required" notation for Access
;	Matrix and eliminated an extra "sysfam set FALSE" when torfam set TRUE
;edit 32, 7-Jan-1991 by MF. Added code by Jay. S. Rouman to support the
;	Ampro Little Board (see CPXBBI.ASM).
;	Also put in a couple of missing .printx's
;edit 31, 2-Nov-1990 by MF.  Moved overlay address to 7000H.
;edit 30, 14-Sep-1990 by MF. Added INCOMPLETE-FILE flag for SET
;	INCOMPLETE-FILE
;edit 29, 11-Sep-1990 by MF.  Moved overlay address for version 4.10.
;	to 6C00H.
; edit 28, 1st September 1990 by Russell Lang, rjl@monu1.cc.monash.edu.au
;	Added support for MicroBee (CPXBEE.ASM).
;
; edit 27, 28-Aug-89 by Mike Freeman, Bonneville Power Administration,
;	P.O. Box 491, Vancouver WA 98666 USA:  add support for Hewlett-
;	Packard HP-125 "Business Assistant" computer using a HP-modified
	;CP/M Version 2.2.
;
; edit 26, 2 December, by OBSchou.  Added code for CP/M-80 Kermit to
;	run on an IBM-PC under Z80MU.  Perverse??  No, its to allow testing
;	of independent code on a PC running CP/M kermit.
;
; edit 25, 27 October, 1987 by OBSchou.  Merged in Sanyo, CompuPro, Genie
;	and TRS Model 4 code, and added four new families.
;	CPXSYO.ASM for the Sanyo, CPXPRO.ASM for the Compupro,
;	CPXTRS.ASM for the TRS-80 Model 4, CPXGNI.ASM for the Genie.
;	Many thanks to G. Smith for these latter two systems.   Also
;	added the WYSE 100 Terminal type to the VDU table.
;
; edit 24, 17 July, 1987 by OBSchou.  Added (hopefully) code from
;	CP/M Kermit 3.5 (WOW) for the Heath 8. (h8quad)  The actual code
;	has been put into the CPXHEA.ASM family file, but I do not actually
;	*KNOW* if this new version works.  Anyone willing to test it out??
;
; edit 23 16 July, 1987 for for Will Rose:
;	edit of 15 Jan 1987 by C W Rose
;	Added code for Micromint SB180 and Ampro 230 terminal.
;
; 	edit of 10 Apr 87 by C W Rose
;	Amended code for pci2651 to handle Telecom Merlin M2215.
;	(8085 at 5 MHz, 2651 USART, port TTY1:, Ampro 230 terminal equivalent).
;	
;	edit of 13 Jul 1987 by C W Rose
;       Added Micromint SB180 with 6/9 MHz. option.
;
; edit 22, 15th July, 1987 by OBSchou for David Moore.  
;	David submitted a paper copy of Kermit 4.05 overlay for a Teletek
;	system:  I have (hopefully) correctly appended his code.  He also
;	send in the code for ADM 22 terminals.
;
; edit 21, 14 July, 1986 by OBSchou for John Shearwood of Birmingham 
;	University.  His edits:
;	edit of Apr 7th, 1987 by JA Shearwood.  Added entry for Cifer Aux port
;	edit of Mar 24 1987 by JA Shearwood, Birmingham.  Added code for Cifer
;	1886 with CP/M Plus
;
;	Also added in code from Chris Miles:
;	edit of 19 May 26, 1987 by C.J.MILES@UMRCC.
;	Kaypro II, Xerox 820 and Big Board II code seperated
;	from CPXSYS.ASM and put in a new family file called
;	CPXBBI.ASM.
;
;	Finally added code from MJ Carter of Nottingham University:
;	edit 16a of 5th Mar 1987 by M J Carter, Nottingham Uni [majoc], to add
;       entry for OEM ScreenTyper (scntpr).  See also CPXFRK.ASM ("fork"),
;       the tail end of CPXLNK.ASM, and the Heath-Zenith family file
;       CPXHEA.ASM (heath, z100, telcon, and scntpr).
;
;	[Note: Martins CPXFRK is another version of CPXSWT.ASM]
;
;
; edit 20, 21 May 1987 by OBSchou for Colin Burns of the Institute 
;	of Neurological Sciences, Glasgow.  Added flag for Hazeltine 1500
;	VDU (h1500)
;
; edit 19, 6th April, 1987 by OBSchou.
;	Added in EQUs for Amstrad 664 and 6128 machines (CPC) and NCR
;	Decsision mate V, bot sets of code submitted by Chris Miles of
;	Manchester University.  NCR code is similar to the PCI2651 code, so
;	NCRDMV chains to CPXTOR.ASM.  CPC cahins to the modified CPXPCW file
;	as submitted by Chris.  *** NOTE *** All Amstrad versions require
;	CP/M 3, so the 664 version must both have the system upgraded to 
;	CP/M 3 and have an aditional RAM pack.  All Amstrad systems require
;	a serial interface.
;
; edit 18, 30 March, 1986. OBSchou.
;	* * * Here Begineth kermit-80 Version 4.09 * * *
;
;	Biggest change is the overlay address has been moved (again) to 6000h
;	and the files have all been diced into families.  M80 (almost) back 
;	in, though I have found some bugs.  Will worry about those later.
;	CPXSYS.ASM (CP4SYS.ASM in V4.05) now is a family file as well.  
;
;	Comments and all that would be much appreciated.
;
;	Bertil Schou,
;	The Computer Centre,
;	Loughborough University of Technology, 
;	Loughborough
;	Leicestershire,  LE11 3TU
;	Great Britain
;
;	tel (0509) 222313
;	E-Mail (Janet) OBSchou at LOUGHBOROUGH.MULTICS
;
;
; edit 17, March 15, by OBSchou to add in support for M80 Macro Assembler.
;       Now its a little messy using the M80 Assembler,asn we have family files
;       and how are we gonna tell M80 what files to use?
;       Sort of Simple: we generate a set of EQUs that only INCLUDE the family
;       file being assembled.  I hope.
;
; edit 16 Dec 1st, 1986 by OBSchou.  Added entry for Amstrad PCW range (PCW)
;	Code in Family file CPXPCW.ASM, submitted by Ian Young of Lattice 
;	Logic Systems.
;
; Edit 15 June 20 1986.  Had to chand org address to 5000h to give room for
;       multi-fcb space for DIR command and other additions in the system
;       indepentent part.  This starts Kermit-80 version 4.08...
;
; Edit 14: March 20, 1986 by OBSchou Loughborough University for 
;       B Robertson, Aberdeen Univ. Computing Centre.
;       Add support for APPLE II with serial cards based on the 6850 ACIA.
;       Mod 380Z support to allow both MDS (5 1/4" discs) and FDS (8" discs)
;       configurations.  Any mistakes on this merge all my fault (OBSchou)
;
; edit 13 22 April, 1986 by OBSchou Loughborough University
;       Changed org address to 4000h to allow for mods to the system
;       independent part for kermit version 4.06
;
; edit 12 5 Febuary, 1986 by OBSchou
;       merged in conditionals for Epson PX8 (px8). Code from Tony Addyman
;       Salford University, England.
;       Added code from other contibutors for Basic Northstar (basicns), 
;       Access-Matrix (access), US Micro Sales s1008 (s1008),
;       Micro Mate (mmate), A.C.E. Discovery (disc).  
;       These I cannot test: please send comments back if these are buggy.
;
; edit 11 29 January 1985 by OBSchou @ multics.lut.ac.uk
;       added in code for 2651 USART for use with CP/M and a VDU
;
; edit 10: 21 November, 1985 by ajcole @ leeds.ai
;       Merged in support for the following:
;       North Star Horizon without SIO-4 (horizon)
;       Comart Communicator (comart)
;       Cromemco TU-ART interface (cmemco)
;       TVI912/920 VDUs (tvi912)
;
; edit 9 24 October by OBSchou.  Merged code from B Robertson from
;       Aberdeen University.  He writes:
;       September 20, 1985 by B Robertson, Aberdeen Univ. Computing Centre.
;       Add support for Research Machines 380Z, North Star Advantage, Acorn
;       BBC with Z80 co-processor and APPLE II with Mountain Computers CPS
;       Multifunction card.
;
; edit 8: 11 October, 1985 by OBSchou
;       tidied up code around Superbrain main/aux port business
;
; edit 7: 11 June, 1985 by O B Schou, Loughborough University of Tech.
;       Loughborough, Leics, England.
;       Added code for Torch (Second processor to BBC-B) and Cifer 1886
;       Hopefully this code will work with Torchpacks, and Cifer 26xx
;       and 28xx series computers.  Edits marked by OBS
;
; edit 6: 9-Feb-85 by CJC
;       Merge Northstar Horizon, Lobo MAX, and Xerox 820 changes:
;       13-Dec-84 Add Northstar Horizon with SIO-4 board, port 5 at 1200 [CSM]
;       13-Jan-85 by Vanya J.Cooper Pima Commun. College Tel: 602-884-6809
;
;pcc001 27-Dec-84       vjc     modules: cp4sys,cp4typ
;       Add conditional for Xerox 820.  I thought at first I could
;       live with the kaypro conditional, but it's enough of a pain
;       that I added it back in.  The clear-to-end-of-screen char
;       is different,  breaking many programs in VT52 mode, and the
;       default escape char control-\, is not at all obvious how
;       to type on the 820 keyboard.  If you muddle through the
;       key translation table, it turns out to be control-comma.
;       Rather than OR xer820 all the occurances of kpII conditionals
;       I added a bbI conditional for all common code for the big
;       board I based machines that is automatically turned on by
;       either kpII or xer820.  This will also make it easier in
;       the future if another flavor of bigboard is added.
;
;pcc010 2-Jan-85        vjc     modules:cp4pkt,cp4typ
;       Control-C during send or recieve clobbers some of the screen
;       and doesn't look nice.  Position the cursor to end of screen
;       before returning to main loop.
;
;pcc013 8-Jan-85        vjc     modules:cp4mit,cp4utl,cp4typ
;       Replace CLOSE command to cancel session logging to SET
;       LOGGING ON/OFF.  This seems to fit in with the command
;       structure better.  Default the log file to KERMIT.LOG
;       incase no previous LOG command.  Logging is also enabled
;       by LOG command, as before.
;
; edit 5: October 13, 1984 by L M Jones, JCC, for New York Botanical Garden
;       Add support for CPT-85xx series of word processors when running CP/M.
;
; edit 4: August 29, 1984 by Bdale Garbee @ CMU
;       Add support for Digicomp Delphi 100 and Netronics Smartvid terminal.
;
; edit 3: July 27, 1984 (CJC)
;       Shuffle files around for easier assembly by both M80 and LASM.
;
; edit 2: June 4, 1984 [Toad Hall]
;       Added Morrow Decision I (the big S100 bus sucker, not the
;       little single motherboard one); added Toad Hall TACTrap to deal
;       with those working through a TAC and its intercept character.
;
; edit 1: May, 1984 (CJC)
;       extracted from CPMBASE.M80 version 3.9; modifications are described
;       in the accompanying .UPD file.
;

FALSE	EQU	0
TRUE	EQU	NOT FALSE

;
; Assembler type.  Define the appropriate one TRUE, the rest FALSE.  (We can't
; use ASM, because it cannot handle multiple input files)
mac80	EQU	FALSE		; For assembly via MAC80 cross-assembler.
m80	EQU	FALSE		; For assembly via Microsoft's M80.
lasm	EQU	TRUE		; For assembly via LASM, a public-domain
				; assembler.
;
;       Address at which the overlay should be loaded.  This will not
;       change often (no more than once per version of KERMIT); it should
;       be updated when a new version of KERMIT is released.
;

ovladr	EQU	7000H		; [18] address = 6c00h for Kermit v4.10
				;[MF]...

cpsker	EQU	FALSE		; building the system-dependent part...

; SET some options to FALSE, then SET  them TRUE if needed
iobyt	SET	TRUE		;assume we dont want IOBYTE..
inout	SET	FALSE		;... or IN/OUT code
termin	SET	FALSE		; we are not using a terminal
; Also set the CPU speed to a default 2.0 Mhz
cpuspd	SET	180		; default to 2 Mhz, in case we dont know
; Assume kit is Z80 based, and set z80 false for non z80 systems.
;z80	SET	TRUE

;Which CP/M system hardware are we building KERMIT-80 for?
;One of the following should be TRUE, the rest FALSE:
;
;We have basically three "classes" of systems:

;Systems supporting the IO-redirection via I/O-Byte

bbc	EQU	FALSE		;[9] Acorn BBC model B
;added code by JAS
cifer2  EQU     FALSE		; Cifer 1886 using io byte flipping [OBS]
cifer3  EQU	FALSE		; Cifer 1886 with CP/M Plus [JAS]
				;  (Not IOBYTE but easier to keep together)
cifaux  EQU     FALSE		; One of above Cifers using AUX port else VL port
dmII	EQU	FALSE		;"Generic" KERMIT-80 for DECMATE II.
gener	EQU	TRUE 		;"Generic" Kermit-80, CP/M calls only.
				; (terminal required)
mikko	EQU	FALSE		;"Generic" KERMIT-80 for MikroMikko
robin	EQU	FALSE		;DEC VT180 = Generic + VT100 screen control

;.. \and Systems supporting direct IN / OUT handling of ports
advant	EQU	FALSE		;[10] North Star Advantage
access	EQU	FALSE		; Access Matrix .. uses port J5 [12]
				; (terminal required) [MF]
ampro	EQU	FALSE		; Ampro Little Board (terminal required)
basicns	EQU	FALSE		; Basic Northstar using printer port (CRT req.)
bbII	EQU	FALSE		;BigBoard II (terminal required)
brainm	EQU	FALSE		;Select Superbrain Main port  **[obs]
braina	EQU	FALSE		;Select Superbrain AUX port  **[obs]
comart	EQU	FALSE		;[10] Comart Communicator
				; (terminal required)
compro	EQU	FALSE		;Compupro Interfacer 4 (or 3) [gv]
				; (terminal required) [MF]
cpt85xx	EQU	FALSE		;CPT-85xx word processor w/CPM (set ADM3A TRUE)
cmemco	EQU	FALSE		;[10] Cromemco (TU-ART) (terminal required)
delphi	EQU	FALSE		;Digicomp Delphi 100 (terminal required)
disc	EQU	FALSE		; Action Computer Enterprises "Discovery"
				; Port B on an 83U user board (CRT required)
genie	EQU	FALSE		;Eaca Genie III
h8quad	EQU	FALSE		;[24] Entry for heath-8.  NOT same as H-89
heath   EQU     FALSE		;For Heath/Zenith H89.
kpII	EQU	FALSE		;Kaypro-II
horizon	EQU	FALSE		;[10] North Star Horizon (mother-board)
				; (terminal required)
m2215	EQU	FALSE		; BT Merlin [23] - uses 2651, Terminal rqd
mmate	EQU	FALSE		; PMC - 101 MicroMate (Crt required)
mmdI	EQU	FALSE		;Morrow Micro Decision I (terminal required)
mdI	EQU	FALSE		;Morrow Decision I (the big sucker)
				; (terminal required) [Toad Hall]
ncrdmv	EQU	FALSE		; NCR Desision Mate V. (2651 USART) (Term rqd.)
norths	EQU	FALSE		;[CSM] NorthStar Horizon with HSIO-4 board
				; (terminal required)
pci2651	EQU	FALSE		; CP/M with 2651 USART.  Needs VDU. [11]
rm380zm	EQU	FALSE		;[14] Research Machines 380Z MDS (5.25" discs)
rm380zf	EQU	FALSE		;[14] Research Machines 380Z FDS (8" discs)
s1008	EQU	FALSE		; US Micro Sales s1008 (Terminal required)
sb6	EQU	FALSE		; SB180 6/9 MHz cpu speed conditionals -
sb9	EQU	FALSE		;   set one of these to TRUE, - it will
				;   automatically set sb180 TRUE
				; (terminal reqd for Sb-180 systems)
scntpr  EQU     FALSE		; [majoc 870305] For OEM ScreenTyper
sanyo	EQU	FALSE 		;For sanyo mbc-1100 series
telcon	EQU	FALSE		;For TELCON Zorba portable
teletek	EQU	FALSE		; Teletek SYSTEMASTER (terminal rqd)
trs80lb	EQU	FALSE		;For Lifeboat 2.25C CP/M Display
trs80pt	EQU	FALSE		;For Pickles + Trout CP/M Display
trsm4	EQU	FALSE		;TRS80 Model 4 under Montezuma Micro CPM 2.2
vector	EQU	FALSE		;For Vector Graphics.
xer820	EQU	FALSE		;[pcc001] Xerox 820
z100    EQU     FALSE		;For Z-100 under CP/M-85.

;.. and Systems doing neither...
apmmdm	EQU	FALSE		;jb Micromodem II in slot 2
ap6551	EQU	FALSE		;jb apple with 6551 ACIA in serial interface
ap6850	EQU	FALSE		;[14] Apple with 6850 ACIA in serial interface
				;[14] e.g PACT, SSM AIO, Aristocard
apcps	EQU	FALSE		;[9] Apple with CP multifunction card
cpc	EQU	FALSE		; Amstrad CPC CP/M Plus computers
cpm3	EQU	FALSE		;"Generic" Kermit-80 for CP/M 3.0 (CP/M Plus)
				; (terminal required)
lobo	EQU	FALSE		;Lobo Max-80
osi	EQU	FALSE		;For Ohio Scientific.
osbrn1	EQU	FALSE		;For Osborne 1
pcw	EQU	FALSE		; Amstrad PCW 8256/8512 computers
px8	EQU	FALSE		;[12] For Epson PX-8
torch	EQU	FALSE		;[obs] Torch does comms via Beeb as IO processor
z80mu	EQU	FALSE		; CP/M-80 Kermit under z80mu emulator on PC
hp125	EQU	FALSE		;[MF]HP-125 Business Assistant, 8-bit data
				; path thru Data Comm 1, 7-bit data path
				; thru Data Comm 2 (requires 8th-bit quoting
				; for binary transfers on Data Comm 2)
				; set VT52 TRUE
mbee	EQU	FALSE		; Microbee Systems - Microbee 

;.. and for Micros, like the MDI, which have "terminals of choice", you must
;select one of these in addition to selecting the micro itself.
;Also select a terminal for "gener" and "cpm3": use "crt" for the TRUE generic.
crt	EQU	FALSE		;Basic CRT, no cursor positioning
adm3a	EQU	TRUE		;Adm3a Display (or CPT built-in display)
adm22	EQU	FALSE		;ADM 22 terminal
h1500	EQU	FALSE		;Hazeltine 1500
smrtvd	EQU	FALSE		;Netronics Smartvid terminal.
soroq	EQU	FALSE		;Soroq IQ-120.. this a guess [OBS]
am230	EQU	FALSE		;Ampro 230 [13]
tvi912	EQU	FALSE		;[10] TVI912/920
tvi925	EQU	FALSE		;TVI925 Display
				; (works for Freedom 100 also)  [Toad Hall]
vt52	EQU	FALSE		;VT52 or equivalent (or H19)
vt100	EQU	FALSE		;VT100 or equivalent
wyse	EQU	FALSE		;Wyse 100 terminal
;
; Several systems are basically the same, with very slight variations,
;	so use common code.  List these sysems below
;
cifer	EQU	cifer2 OR cifer3	; DO NOT TOUCH THIS LINE
brain	EQU	brainm OR braina	;For Intertec SuperBrain. **[obs]
;
; flag 380Z system if either selected
;
rm380z	EQU rm380zm OR rm380zf ;[14]
;
trs80	EQU	trs80lb	OR trs80pt ; if either, flag TRS-80 system.
bbI	EQU	kpII OR	xer820	;[pcc001] flag for bigboard I
sb180	EQU	sb6 OR sb9	; Micromint SB180 (BYTE Oct 85)
;
; flag apple system if either selected
;
apple	EQU	apmmdm OR ap6551 OR ap6850 OR apcps
;
; also set termin(al) TRUE if any terminal selected (crt included)
termin	SET	crt OR adm3a OR adm22 OR h1500 OR smrtvd OR am230
termin	SET	termin OR tvi912 OR tvi925 OR vt52 OR vt100
termin	SET	termin OR wyse OR soroq

; Now set iobyt or inout TRUE for those systems doing so
; IOBYTE systems...
IF robin OR dmII OR gener OR mikko OR cifer2 OR bbc;[**obs]
iobyt	SET	TRUE		;Short conditional for above
ENDIF;robin OR dmII OR gener OR cifer2 OR bbc

; INOUT systems...
IF brain OR vector OR sanyo or compro
inout	SET	TRUE		;Short conditional for above
ENDIF;brain OR vector OR sanyo OR compro

IF heath OR h8quad OR z100 OR trs80 OR telcon OR bbI
inout	SET	TRUE		;Short conditional for above
ENDIF;heath OR h8quad OR z100 OR trs80 OR telcon OR bbI

IF bbII	OR mmdI	OR mdI OR delphi OR cpt85xx OR norths	;running out of room
inout	SET	TRUE		;Short conditional for above
ENDIF;bbII OR mmdI OR mdI OR delphi OR cpt85xx OR norths

IF advant OR rm380z OR comart OR horizon OR cmemco	;[9] [10] more room here
inout	SET	TRUE		;Short conditional for above
ENDIF;advant OR rm380z OR comart OR horizon OR cmemco

IF pci2651 OR m2215 OR sb180 OR ncrdmv OR teletek;[11] and even more room
inout	SET	TRUE		;Short conditional for above
ENDIF	;pci2651 OR m2215 OR sb180 OR ncrdmv OR teletek [11]

IF access OR basicns OR	s1008 OR mmate OR disc ; [12]
inout	SET	TRUE		;Short conditional for above
ENDIF ; access OR basicns OR s1008 OR mmate OR disc [12]

IF genie OR trsm4 OR ampro
inout	SET	TRUE		;Short conditional for above
ENDIF ; genie OR trsm4 OR ampro


; Toad Hall TAC Trap:  If you're going through a TAC, it will
; cough on its Intercept Character (usually a @ (* - 40H)).  Sending it
; twice forces the TAC to recognize it as a valid ASCII character,
; and it'll send only one on to the host.  If you've SET the TACTrap
; to OFF, it will be a null character, and nothing will happen.  If you
; set it on, it will be your selected TAC intercept character (or will
; default to the common intercept char, '@'.
; If you never expect to have to work through such a beastie, just set
; TAC to false and forget all this mess.  [Toad Hall]

tac	EQU	FALSE		; gonna work through a TAC?
tacval	EQU	'@'             ;Typical TAC intercept character

; Processor speed in units of 100KHz
; for bbII, kpII, cpt85xx, advance, apple,bbc,px8 & rm380z timing loop [12]
; We have to set these before CPXCOM to make sure we update the CPU speed.

; The following systems I have no idea of cpu speed. Can anyone oblige??
;	robin, dmII, mikko, vector, heath, h8quad, z100, scntpr
;	trs80 (both), telcon, mmdI, mdI, delphi, ncrdmv,
;	cromemco, teletek, osi, lobo

IF z80mu
cpuspd	SET	2		; a PC is about 200khz Z80 equivalent
ENDIF; z80mu

IF apple OR cpt85xx OR px8 OR heath OR h8quad ;[9] [12] What rate is heath?
cpuspd	SET	20		; Apple Softcard, CPT-85xx: 2.0 MHz
				; ('cause of integral video?)
ENDIF; apple OR cpt85xx OR px8 OR heath OR h8quad [12]

IF kpII	OR xer820 OR scntpr OR osbrn1 ;[9] What speed is scntpr??
cpuspd	SET	25		; original Kaypro II,Xerox 820: 2.5 MHz
ENDIF;kpII OR xer820 OR scntpr OR osbrn1

IF PCW or CPC
cpuspd	SET	33 		; all 4MHz but insterted wait states
				; reduce to an effective 3.3 MHz.
ENDIF	;pcw OR cpc

IF brain OR advant OR bbII OR torch OR z100 OR genie OR trsm4
cpuspd	SET	40		; 4.0 MHz CPU
ENDIF; brain OR advant OR bbII OR torch OR z100 OR genie OR trsm4

IF cifer OR rm380z OR comart OR horizon OR norths
cpuspd	SET	40		; 4.0 MHz CPU
ENDIF; cifer OR rm380z OR comart OR horizon OR norths

IF disc	OR mmate OR s1008 OR access OR basicns ;[29] This is a guess.. Most are 4Mhz
cpuspd	SET	40		; 4.0 MHz CPU
ENDIF	;disc OR mmate OR s1008 OR access OR basicns [29]

IF m2215
cpuspd	SET	50		; BT Merlin Rair Black Box is 8085 at 5 Mhz
ENDIF	;m2215

IF bbc or sb6
cpuspd	SET	60		; BBC or SB-180 with 6Mhz Z80/61480
ENDIF;bbc OR sb6

IF sb9
cpuspd	SET	90		; SB-180 with 9 Mhz clock
ENDIF;sb9

IF hp125 OR telcon
cpuspd	SET	40		;[MF]HP125 or TELCON
ENDIF;hp125 OR telcon 

IF mbee
cpuspd	SET	33		; Microbee has 3.375MHz Z80
ENDIF; mbee

; Set Z80 flag FALSE for non Z80 or unknown CPU systems
IF	FALSE			; assume all systems are not z80 based
;z80	SET	FALSE
ENDIF	;FALSE

; Now, lets see what family we are assembling for.  Reset all 
;	family file to FALSE

torfam  SET     FALSE		; not Torch family file
ciffam	SET	FALSE		; not Cifer kit
appfam	SET 	FALSE		; not Apples
norfam	SET	FALSE		; not North Star kit
pcwfam	SET	FALSE		; not Amstrad PCW kit
bbifam	SET	FALSE		; not the BBI family
heafam	SET	FALSE		; not Heath, Z100, telcon,or screentyper
sbfam	SET	FALSE		; not an SB180 system
merfam	SET 	FALSE		; not a BT Merlin system
sanfam	SET	FALSE		; not a Sanyo
comfam	SET	FALSE		; not a compupro
genfam	SET	FALSE		; not a genie
trsfam	SET	FALSE		; not a trs-80 Model 4
z80fam	SET	FALSE		; not z80mu system
beefam	SET	FALSE		; not a Microbee system
sysfam	SET	TRUE		; ... but assume the worst, and its in
				; the CPXSYS.ASM file


IF      (torch OR pci2651 OR ncrdmv OR brain)   ;[15]
torfam  SET     TRUE            ; we are to use the Torch family file
.printx * torfam set TRUE *
;(Yeah, I know, there are more than Torch systems in it)
ENDIF	;(torch OR pci2651 OR ncrdmv OR brain) [15]

IF      (cifer)
ciffam	SET	TRUE		; we are to use the cifer family file
.printx * ciffam set TRUE *
ENDIF	;cifer

IF      apple   ;[15]
appfam	SET 	TRUE		; apples
.printx * appfam set TRUE *
ENDIF   ;apple [15]

IF      (horizon OR basicns OR norths OR advant OR comart) ;[15]
norfam	SET	TRUE		; north star kit
.printx * norfam set TRUE *
ENDIF   ;(horizon OR basicns OR norths OR advant OR comart) [15]

IF      (pcw OR cpc)	;[15]
pcwfam	SET	TRUE		; Amstrad PCW kit
.printx * pcwfam set TRUE *
ENDIF   ;pcw OR cpc [15]

IF      (kpII OR xer820 OR bbII OR ampro)
bbifam	SET	TRUE		; The Bigboard, Kaypro, Xerox and Ampro family
.printx * bbifam set TRUE *
ENDIF	;(kpII or xer820 OR bbII OR ampro)

IF (heath OR h8quad OR telcon OR z100 OR scntpr)
heafam	SET	TRUE		; Doing Heath, z100, telcon, or screentyper
.printx * heafam set TRUE *
ENDIF   ;(heath OR h8quad OR telcon OR z100 OR scntpr)

IF sb180
sbfam	SET	TRUE		; doing an SB180 system
.printx * sbfam set TRUE *
ENDIF	; sb180

IF m2215
merfam	SET 	TRUE		; doing a BT Merlin system
.printx * merfam set TRUE *
ENDIF	; m2215

IF sanyo
sanfam	SET 	TRUE		; doing a Sanyo MBC-1100 system
.printx * sanfam set TRUE *
ENDIF	; sanyo

IF compro
comfam	SET 	TRUE		; doing a Compupro system
.printx * comfam set TRUE *
ENDIF	; compro

IF genie
genfam	SET 	TRUE		; doing a Genie system
.printx * genfam set TRUE *
ENDIF	; genie

IF trsm4
trsfam	SET 	TRUE		; doing a TRS-80 M4 system
.printx * trsfam set TRUE *
ENDIF	; trs4m

IF z80mu
z80fam	SET 	TRUE		; doing a z80mu emulation
.printx * z80fam set TRUE *
ENDIF	; z80mu

IF mbee
beefam	SET	TRUE		; doing a Microbee system
.printx * beefam set TRUE *
ENDIF	; mbee

; Now, if none of the above, then its the older CPXSYS.ASM file we want

IF (torfam OR ciffam OR appfam OR norfam OR sanfam OR comfam) AND sysfam
sysfam	SET	FALSE		; Were not doing the CPXSYS.ASM file
.printx * sysfam set FALSE *
ENDIF	; (torfam OR ciffam OR appfam OR norfam OR sanfam OR comfam) AND sysfam

IF (pcwfam OR bbifam OR heafam OR sbfam OR merfam) AND sysfam
sysfam	SET	FALSE		; Were not doing the CPXSYS.ASM file
.printx * sysfam set FALSE *
ENDIF	; (pcwfam OR bbifam OR heafam OR sbfam OR merfam) AND sysfam

IF (genfam OR trsfam OR z80fam OR beefam) AND sysfam
sysfam	SET	FALSE		; Were not doing the CPXSYS.ASM file
.printx * sysfam set FALSE *
ENDIF	; (genfam OR trsfam OR z80fam OR mbeefam) AND sysfam

IF sysfam
.printx * sysfam set TRUE *
ENDIF

IF lasm
	LINK	CPSDEF		; Use the system independent declares
ENDIF;lasm  [Toad Hall]

; If we're still here, must be M80 or MAC80.  Collect the rest of
; the sources.
.sfcond


        INCLUDE CPSDEF.ASM      ; common definitions
        INCLUDE CPXLNK.ASM      ; linkage area description
	INCLUDE	CPXCOM.ASM	; include common code
        INCLUDE CPXSWT.ASM      ; this wont do much, but will announce machine

IF      torfam                  ;[15]
        INCLUDE CPXTOR.ASM      ; we are assembling for Torch, Cifer etc
ENDIF   ;torfam                 [15]

IF	ciffam
	INCLUDE	CPXCIF.ASM	; we are assembling for a Cifer
ENDIF	;ciffam

IF      appfam                  ;[15]
        INCLUDE CPXAPP.ASM      ; we are assembling for an apple
ENDIF   ;appfam                 [15]

IF      norfam                  ;[15]
        INCLUDE CPXNOR.ASM      ; we are assembling a NortStar machine
ENDIF   ;norfam                 [15]

IF      pcwfam                  ;[15]
        INCLUDE CPXPCW.ASM      ; we are assembling for the Amstrad PCW machine
ENDIF   ;pcwfam                 [15]

IF      bbifam
        INCLUDE CPXBBI.ASM	; assembling for BigBoard, Kaypro, Xerox
				; & Ampro Little Board
ENDIF   ;bbifam

IF      sysfam                  ;[15]
        INCLUDE CPXSYS.ASM      ; system-dependent code and tables (Part 1)
        INCLUDE CPXSY2.ASM      ; system-dependent code and tables (Part 2)
ENDIF   ;sysfam                 [15]

IF	heafam
	INCLUDE CPXHEA.ASM
ENDIF	;heafam

IF	m2215
	INCLUDE	CPXMRL.ASM
ENDIF	;m2215

IF	sbfam
	INCLUDE	CPXSB.ASM
ENDIF	;sbfam

IF	sanfam
	INCLUDE	CPXSYO.ASM
ENDIF	;sanfam

IF	comfam
	INCLUDE	CPXPRO.ASM
ENDIF	;comfam

IF	genfam
	INCLUDE	CPXGNI.ASM
ENDIF	;genfam

IF	trsfam
	INCLUDE	CPXTM4.ASM
ENDIF	;trsfam

IF	z80fam
	INCLUDE	CPXZ80.ASM
ENDIF	;z80fam

IF	beefam
	INCLUDE CPXBEE.ASM
ENDIF	;beefam

IF termin			; any terminal selected?
        INCLUDE CPXVDU.ASM      ;[15] Just in case we need a VDU...
ENDIF	;termin
        END
