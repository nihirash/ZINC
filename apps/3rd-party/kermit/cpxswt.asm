IF NOT lasm
.printx * CPXSWT.ASM *
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
;	This file is a simple family or system file switcher, selecting
;	one of several family files, or selectin CPXSYS.ASM (now modified)
;	if a family file does not exist.
;
;
; revision history:
;
;edit 10, 7-Jan-1991 by MF. Added code by Jay S. Rouman to support the
;	Ampro Little Board (see CPXBBI.ASM) and PRINTX for the HP-125.
; edit 9, 1st September 1990 by Russell Lang, rjl@monu1.cc.monash.edu.au.
;	Added Microbee support.
; edit 8, 2 December by OBSchou.  Added Z80MU "system" to allow kermit-80
;	debugging on a PC!
;
; edit 7, 27 October, 1987 by OBSchou.  Added bits for Sanyo, Compupro, 
;	Genie and TRS-80 M4.
;
; edit 6, 16 July, 1987 for Will Rose, who has submitted code for
;	Micromint SB180 (6 and 9 Mhz) and a BT Merlin (alias RAIR)
;
; edit 5, 15 July, 1987 by OBSchou for David Moore, who has submitted
;	code for a Teletek SYSTEMASTER and for ADM22 terminals.
;
; edit 4, 14 July 1987 by OBSchou for JA Shearwood of Birmingham University,
;	Chris Miles of Manchester University.  Added a Cifer family file
;	for John, and added a BigBoard-Kaypro-Xerox family file for Chris
;	Finally, added in new family file for Heath, telcon, z100 and scntpr
;	systems for Martin Carter of Nottingham University.
;
; edit 3, 6 April, 1986 by OBSchou.
;	Added in switching for NCR Desision Mate V and Amstrad CPC 664/6128
;	systems.
;
; edit 2, March 16, 1987 by OBSchou.
;       added in support for m80 macro assembler.
;
; edit 1 28 January, 1987 by OBSchou.
;	Take out the series of printx etx and selection of systems and
;	leave this with only the system dep. code for systems without
;	a family file.  Hopefully, this file will go alltogether in time.
;
; Keep module name, edit number, and last revision date in memory.
swtver:	db	'CPXSWT.ASM (10)  7-Jan-1991 $'
;
; Assembly time message to let me know I'm building the right version.
; LASM generates an 'S' error along with the message, which is messy, but
; better than trying to put everything inside a IF m80 OR mac80 conditional,
; because LASM doesn't like nested IF's, either.


IF (torfam AND lasm)
;Link to the module with the code for Superbrains, Torch, Cifer and pci2651
LINK CPXTOR.ASM		; also NCR DMV systems
ENDIF;(torfam AND lasm) - m80 use: INCLUDE from CPXTYP.ASM

IF (ciffam AND LASM)
; Link to the Cifer family file.  (Cifer code previously on CPXTOR.ASM)
LINK CPXCIF.ASM		; Cifer family file
ENDIF	;(ciffam AND lasm) - m80 use: INCLUDE from CPXTYP.ASM

IF (appfam AND lasm) ;[33] apple frogs as a separate family..
; Link to the APPLE family...
LINK CPXAPP.ASM
ENDIF ;(appfam AND lasm) - m80 use: INCLUDE from CPXTYP.ASM

IF (norfam AND lasm); Link to the Northstar family (and Comart)
; Link to the NorthStar family file
LINK CPXNOR.ASM
ENDIF; (norfam AND lasm) - m80 use: INCLUDE from CPXTYP.ASM

IF (pcwfam AND lasm) ;[35] Amstrad PCW 8256/8512  or CPC systems
; Link to the Amstrad PCW family
LINK CPXPCW.ASM
ENDIF ;(cpwfam AND lasm) - m80 use: INCLUDE from CPXTYP.ASM

IF (bbifam AND lasm) ;Bigboard, Kaypro and Xerox 820 file
; Link to the Bigboard family
.printx * Linking to the BigBoard family *
LINK CPXBBI.ASM
ENDIF ;(bbifam AND lasm) - m80 use: INCLUDE from CPXTYP.ASM

IF (heafam AND lasm)	; heath, z100, telcon, and scntpr systems
; Link to the Heath-telcon-screentyper family
.printx * Linking to the Heath-telcon-screentyper family *
LINK CPXHEA.ASM
ENDIF	;(heafam) - m80 use: INCLUDE from CPXTYP.ASM

IF (sbfam AND lasm)
; Link to the SB180 Family file
,printx * Linking to the SB180 Family file *
LINK CPXSB.ASM
ENDIF	; (sbfam AND lasm) - m80 use: INCLUDE from CPXTYP.ASM

IF (m2215 AND lasm)
; Link to the RAIR/ BT Merlin code
.printx * Linking to the Merlin/Rair code *
LINK CPXMRL.ASM
ENDIF	; (m2215 AND lasm) - m80 use: INCLUDE from CPXTYP.ASM

IF (sanfam AND lasm)
; Link to the Sanyo code
.printx * linking to the sanyo code *
LINK CPXSYO.ASM
ENDIF	; (sanfam AND lasm) - m80 use: INCLUDE from CPXTYP.ASM

IF (comfam AND lasm)
; Link to the compupro code
.printx * linking to the Compupro code *
LINK CPXPRO.ASM
ENDIF	; (comfam AND lasm) - m80 use: INCLUDE from CPXTYP.ASM

IF (genfam AND lasm)
; Link to the Genie family code
.printx * linking to the Genie code *
LINK CPXGNI.ASM
ENDIF	; (genfam AND lasm) - m80 use: INCLUDE from CPXTYP.ASM

IF (trsfam AND lasm)
; Link to the TRS-80 family file
.printx * linking to the TRS family file*
LINK CPXTM4.ASM
ENDIF	; (trsfam AND lasm) - m80 use: INCLUDE from CPXTYP.ASM

IF (z80fam AND lasm)
; Link to the Z80MU family file
.printx * linking to the Z80MU family file*
LINK CPXZ80.ASM
ENDIF	; (z80fam AND lasm) - m80 use: INCLUDE from CPXTYP.ASM

IF (beefam AND lasm)
; Link to the Microbee family file
.printx * linking to the Microbee family file *
LINK CPXBEE.ASM
ENDIF	; (beefam AND lasm) - m80 use: INCLUDE from CPXTYP.ASM


; If we have come here, we are assembling the CPXSYS.ASM file

IF robin
.printx	* Assembling KERMIT-80 for the DEC VT180 *
ENDIF

IF vector
.printx	* Assembling KERMIT-80 for the Vector Graphics *
ENDIF

IF osi
.printx	* Assembling KERMIT-80 for the Ohio Scientific *
ENDIF

IF heath
.printx	* Assembling KERMIT-80 for the Heath/Zenith 89 *
ENDIF

IF z100
.printx	* Assembling KERMIT-80 for the Heath/Zenith Z100 *
ENDIF

IF trs80
.printx	* Assembling KERMIT-80 for the TRS-80 II *
ENDIF

IF osbrn1
.printx	* Assembling KERMIT-80 for the Osborne 1 *
ENDIF

IF telcon
.printx	* Assembling KERMIT-80 for the Telcon Zorba *
ENDIF

IF dmII
.printx	* Assembling KERMIT-80 for the DECmate II *
ENDIF

IF gener
.printx	* Assembling Generic KERMIT-80 *
ENDIF

IF cpm3
.printx	* Assembling Generic KERMIT-80 for CP/M	3.0 *
ENDIF

IF hp125
.printx * Assembling Kermit-80 for the HP-125 Series 100 *
ENDIF ;hp125

IF kpii
.printx	* Assembling Kaypro II KERMIT-80 *
ENDIF

IF xer820			;[pcc001]
.printx	* Assembling Xerox 820 KERMIT-80 *
ENDIF				;[pcc001]

IF bbII
.printx	* Assembling BigBoard II KERMIT-80 *
ENDIF

IF ampro
.printx	* Assembling Ampro Little Board KERMIT-80 *
ENDIF

IF mdI
.printx	* Assembling for Morrow	Decision I *
ENDIF	;mdI  [Toad Hall]

IF mmdI
.printx	* Assembling for Morrow	Micro Decision I *
ENDIF	;mmdI

IF mikko
.printx	* Assembling MikroMikko	Kermit-80 *
ENDIF

IF delphi	;[7]
.printx	* Assembling Digicomp Delphi 100 Kermit-80 *
ENDIF		;[7]

IF cpt85xx
.printx	* Assembling CPT-85xx (under CompuPak CP/M) Kermit-80 *
ENDIF

IF cmemco	;[25]
.printx	* Assembling KERMIT-80 for the Cromemco	(TU-ART) *
ENDIF;cmemco

IF bbc	;[22]
.printx	* Assembling Kermit-80 for BBC with Z80	co-processor *
ENDIF	;[22]

IF rm380z	;[22]
.printx	* Assembling Kermit-80 for Research Machines 380Z *
ENDIF	;[22]

IF px8		;[29]
.printx	* Assembling Kermit-80 for Epson PX-8 *
ENDIF	;px8 [29]

IF mmate	;[29]
.printx	* Assembling KERMIT-80 for the PMC MicroMate *
ENDIF	;mmate [29]

IF disc	;[29]
.printx	* Assembling KERMIT-80 for the A. C. E.	Discovery *
ENDIF	;disc [29]

IF s1008	;[29]
.printx	* Assembling KERMIT-80 for the MicroSales s1008	*
ENDIF	;s1008 [29]

IF access	;[29]
.printx	* Assembling Kermit-80 for the ACCESS-MATRIX computer *
ENDIF	;access [29]

IF lobo		;[hh]
.printx	* Assembling Kermit-80 for the Lobo MAX-80 *
ENDIF;lobo [hh]

IF teletek
.printx * Assembling Kermit-80 for the Teletek *
ENDIF	;teletek

;
;
; If here, we have not linked to a family, so link to CPXSYS.ASM
IF lasm
	LINK	CPXSYS.ASM
ENDIF	;lasm
;
; If we are using m80, then the CPXSYS.ASM file will be INCLUDED from CPXTYP
;



