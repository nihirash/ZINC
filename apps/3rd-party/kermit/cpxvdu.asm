IF NOT lasm
.printx * CPXVDU.ASM *
ENDIF	;NOT lasm
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
;edit 6, 12-Oct-1990 by MF.  Added a semicolon to the comment "If we
;	need cursor ..." so it isn't seen as an undefined symbol
; edit 5, 20 July by OBSchou.  Put in the cursor positioning code for 
;	all the terminal supported, and moved the vtval EQUs and defesc EQUs
;	here if the system requires andn external terminal.  If the system 
;	has a 'built in' terminal (ie own scrteen driver) you will not come
;	to this file, so you must declare these three lables etc in your
;	own code.
;	This will allow only those systems requiring a terminal to require
;	CPXVDU.ASM during assembly.
;
; edit 4, 16 July, 1987 by OBSchou for will Rose.
;	Added code for Ampro 230 terminal
;
; edit 3, 15 July, 1987 by OBSchou for David Moore.  Added adm22 terminal
;	codes.
;
; edit 2 21 May, 1987 by OBSchou.  Added in definitions for Hazeltine 1500
;	submitted by Colin Burns of the Institute of Neurological Sciences
;	in Glasgow.
; edit 1 ???  date. Split the terminal codes off from the CPXSYS.ASM file
;
vduver:	db	'CPXVDU.ASM  (6)  12-Oct-1990 $' ;file, edit version,, date.


; First, print out what terminal (if any) we are assembling for

IF crt
.printx	* generic CRT selected *
ENDIF

IF adm3a
.printx	* ADM3A	selected *
ENDIF

IF adm22
.printx	* ADM22 selected *
ENDIF

IF smrtvd	;[7]
.printx	* Netronics Smartvid-80	selected *
ENDIF		;[7]

IF tvi912
.printx	* TVI912/920 selected *
ENDIF

IF tvi925
.printx	* TVI925 selected *
ENDIF

IF vt52
.printx	* VT52 selected	*
ENDIF

IF vt100
.printx	* VT100	selected *
ENDIF

IF am230
.printx * Ampro 230 terminal selected *
ENDIF

IF wyse
.printx * Wyse 100 terminal selected *
ENDIF
;

;
; If we need cursor positioning, here is the code to do it 
;
;       Screen manipulation routines
;       csrpos - move to row B, column C
;
;       csrpos for terminals that use a leadin sequence followed
;        by (row + 31.) and (column + 31.)
;
IF NOT (vt100 OR crt OR h1500)
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
ENDIF;NOT (vt100 OR crt OR h1500)
;
;
;
;
;       csrpos for ANSI terminals
;
IF vt100
csrpos: push    b               ; save coordinates
        lxi     d,curldn        ; get cursor leadin sequence
        call    prtstr          ; print it
        pop     h               ; peek at coordinates
        push    h               ;  then save away again
        mov     l,h             ; l = row
        mvi     h,0             ; hl = row
        call    nout            ; output in decimal
        mvi     e,';'           ; follow with semicolon
        call    outcon          ; print it
        pop     h               ; restore column
        mvi     h,0             ; hl = column
        call    nout
        mvi     e,'H'           ; terminate with 'move cursor' command
        jmp     outcon          ; output it and return
ENDIF;vt100

;Definition for Hazeltine 1500  does things a little strange.
;
IF h1500
csrpos: push    b               ; save coordinates
        lxi     d,curldn        ; get cursor leadin sequence
        call    prtstr          ; print it
        pop     h               ; restore coordinates
        mov     a,l             ; get col
        nop
	nop
;	adi     (' '-1)         ; space is row one
        mov     e,a
        push    h
        call    outcon          ; output row
        pop     h
        mov     a,h             ; get row
        adi     (' '-1)         ; space is column one
        mov     e,a
        jmp     outcon          ; output it and return
ENDIF; h1500


IF crt				; systems without cursor positioning
csrpos: ret			; dummy routine referenced by linkage section
ENDIF;crt
;
;
;
; Now for the rest of CPXVDU.ASM
;
;
;
IF crt 	;Set flags etc for systems with CRT selected
defesc  EQU     '\'-100O        ;Still Control-\ (just ran out of room...)
vtval   EQU     0FFH            ;  we can't support VT52 emulation
ttytyp:	db	'Generic (Dumb) CRT Terminal type selected $'
ENDIF;crt

;

IF vt52		; DEC VT52
ttytyp:	db	'VT52$'
ENDIF;vt52

IF vt52
vtval	EQU	0	; we don't need VT52 emulation
defesc	EQU	'\'-100O        ;Still Control-\ (just ran out of room...)
outlin:	db	esc,'H',esc,'J',cr,lf,tab,tab,'$'
erascr:	db	esc,'H',esc,'J$'        ;Clear screen and go home.
eralin:	db	cr,esc,'K$'             ;Clear line.
curldn:	db	esc,'Y$'                ;cursor leadin
ttab:					;Table start location.
ta:	db	esc,'A$',0              ;Cursor up.
tb:	db	esc,'B$',0              ;Cursor down.
tc:	db	esc,'C$',0              ;Cursor right.
td:	db	esc,'D$',0              ;Cursor left
te:	db	esc,'E$',0              ;Clear display
tf:	db	esc,'F$',0              ;Enter Graphics Mode
tg:	db	esc,'G$',0              ;Exit Graphics mode
th:	db	esc,'H$',0              ;Cursor home.
ti:	db	esc,'I$',0              ;Reverse linefeed.
tj:	db	esc,'J$',0              ;Clear to end of screen.
tk:	db	esc,'K$',0              ;Clear to end of line.
ENDIF;vt52
;

IF adm22
vtval	EQU	1		; we can do VT52 emulation
defesc	EQU	'\'-100O        ;Still Control-\ (just ran out of room...)
ttytyp:	db	'ADM22$'
outlin:	db	1ah,cr,lf,tab,tab,'$'
erascr:	db	1ah,'$'			;Clear screen and go home.
eralin:	db	esc,'>$'		;Clear line.
curldn:	db	esc,'=$'		;Cursor lead-in
ttab:					;Table start location.
ta:	db	0BH,'$',0,0             ;Cursor up.
tb:	db	lf,'$',0,0		;Cursor down.
tc:	db	0CH,'$',0,0             ;Cursor right.
td:	db	bs,'$',0,0              ;Cursor left
te:	db	1ah,':$',0              ;Clear display
tf:	db	'$',0,0,0               ;(can't) Enter Graphics Mode
tg:	db	'$',0,0,0               ;(can't) Exit Graphics mode
th:	db	1EH,'$',0,0             ;Cursor home.
ti:	db	0BH,'$',0,0             ;Reverse linefeed.
tj:	db	esc,'Y$',0              ;Clear to end of screen.
tk:	db	esc,'T$',0              ;Clear to end of line.
ENDIF;adm22
;

IF am230
; Select initial setting for VT-52 emulation flag.
vtval	EQU	1
defesc	EQU	'\'-100O	;The default is Control-\ -- it's easier 
ttytyp:	db	'Am230$'
outlin:	db	'Z'-64,0,0,cr,lf,'$'
erascr:	db	'Z'-64,0,0,'$'		;Clear screen and home
eralin:	db	esc,'R$',0		;Erase line
curldn:	db	cr,esc,'=$'		;Cursor lead-in
ttab:	;Table start location		;(MUST be 4 bytes each)
ta:	db	'K'-64,'$',0,0		;Cursor up, stop at top
tb:	db	'V'-64,'$',0,0		;Cursor down, stop at bottom
tc:	db	'L'-64,'$',0,0		;Cursor right, stop at right
td:	db	'H'-64,'$',0,0		;Cursor left, stop at left
te:	db	'Z'-64,0,0,'$'		;Clear display (2 pad nulls)
tf:	db	'$',0,0,0		;(can't) Enter Graphics mode
tg:	db	'$',0,0,0		;(can't) Exit Graphics mode
th:	db	1EH,'$',0,0		;Cursor home
ti:	db	esc,'j$',0		;Reverse linefeed, scroll
tj:	db	esc,'Y$',0		;Clear to end of sreen
tk:	db	esc,'T$',0		;Clear to end of line
ENDIF
;
;


IF vt100
ttytyp:	db	'VT100$'
ENDIF;vt100


IF vt100
; Note that we cannot support Graphics Mode or the H19 erase-screen command
; (<esc>E), because the sequences are more than three bytes.
defesc	EQU	'\'-100O        ;Still Control-\ (just ran out of room...)
vtval	EQU	0		; we probably don't want VT52 emulation
outlin:	db	esc,3CH,esc,'[H',esc,'[J',cr,lf,tab,tab,'$'
erascr:	db	esc,'[H',esc,'[J$'      ;Clear screen and go home.
eralin:	db	cr,esc,'[K$'            ;Clear line.
curldn:	db	esc,'[$'                ; Cursor leadin
ttab:
ta:	db	esc,'[A$'               ; Cursor up.
tb:	db	esc,'[B$'               ; Cursor down.
tc:	db	esc,'[C$'               ; Cursor right.
td:	db	esc,'[D$'               ; Cursor left
te:	db	'$',0,0,0               ; (can't) Clear display
tf:	db	'$',0,0,0               ; (don't) Enter Graphics Mode
tg:	db	'$',0,0,0               ; (don't) Exit Graphics mode
th:	db	esc,'[H$'               ; Cursor home.
ti:	db	esc,'M$',0              ; Reverse linefeed.
tj:	db	esc,'[J$'               ; Clear to end of screen.
tk:	db	esc,'[K$'               ; Clear to end of line.
ENDIF;vt100
;

IF gener or cpm3
sysver:	db	'Generic CP/M-80$'
ENDIF;gener or cpm3


IF soroq			;[29]  Should this not be with terminals.....
ttytyp:	db	'Soroc IQ-120$'
outlin:	db	1EH,esc,'Y',cr,lf,tab,tab,'$'
erascr:	db	1EH,esc,'Y$'  ;clear screen and home cursor
eralin:	db	cr,esc,'T$'  ;clear line
curldn:	db	esc,'=$'  ;cursor lead-in string
delstr:	db	bs,' ',bs,bs,'$' ;??adjust for echoing delete
ttab:					;table start location
ta:	db	0BH,'$',0               ;cursor up
tb:	db	0AH,'$',0               ;cursor down
tc:	db	0CH,'$',0               ;cursor right
td:	db	08H,'$',0               ;cursor left
te:	db	esc,'*$',0              ;clear display (homes cursor)
tf:	db	esc,')$',0              ;enter inverse video mode
tg:	db	esc,'($',0              ;exit inverse video mode
th:	db	01EH,'$',0              ;home cursor
ti:	db	0BH,'$',0               ;reverse linefeed (insert line)
tj:	db	esc,'Y$',0              ;clear to end of screen
tk:	db	esc,'T$',0              ;clear to end of line
ENDIF;soroq

IF crt
outlin:	db	cr,lf,'Starting ...$'
erascr	equ	crlf			;"Home & clear" (best we can do).
eralin:	db	'^U',cr,lf,'$'          ;Clear line.
prpack:	db	cr,lf,'RPack: $'
pspack:	db	cr,lf,'SPack: $'
ttab	equ	0			; no VT52 table
ENDIF;crt
;

IF tvi912
vtval	EQU	1		; we do emulation
defesc  EQU     '\'-100O        ;Still Control-\ (just ran out of room...)
ttytyp:	db	'TVI912/920$'
outlin:	db	'Z'-64,0,0,cr,lf,'$'
erascr:	db	'Z'-64,0,0,'$'          ;Clear screen and home
eralin:	db	esc,'Y$',0              ;Clear to end of sreen
curldn:	db	cr,esc,'=$'             ;Cursor lead-in
ttab:	;Table start location           ;(MUST be 4 bytes each)
ta:	db	'K'-64,'$',0,0          ;Cursor up, stop at top
tb:	db	'J'-64,'$',0,0          ;Cursor down, stop at bottom
tc:	db	'L'-64,'$',0,0          ;Cursor right, stop at right
td:	db	'H'-64,'$',0,0          ;Cursor left, stop at left
te:	db	'Z'-64,0,0,'$'          ;Clear display (2 pad nulls)
tf:	db	'$',0,0,0               ;(can't) Enter Graphics mode
tg:	db	'$',0,0,0               ;(can't) Exit Graphics mode
th:	db	1EH,'$',0,0             ;Cursor home
ti:	db	esc,'j$',0              ;Reverse linefeed, scroll
tj:	db	esc,'Y$',0              ;Clear to end of sreen
tk:	db	esc,'T$',0              ;Clear to end of line
ENDIF;tvi912
;
;

IF tvi925
;(incidentally, works fine for Freedom 100 also  [Toad Hall])
;adm3a entry and tvi925 entry separated to remove warning message.
vtval	EQU	1		; we VT52 emulation
defesc  EQU     '\'-100O        ;Still Control-\ (just ran out of room...)
ttytyp:	db	'TVI925$'
outlin:	db	'Z'-64,0,0,cr,lf,'$'
erascr:	db	'Z'-64,0,0,'$'          ;Clear screen and home
eralin:	db	esc,'Y$',0              ;Clear to end of sreen
curldn:	db	cr,esc,'=$'             ;Cursor lead-in
ttab:	;Table start location           ;(MUST be 4 bytes each)
ta:	db	'K'-64,'$',0,0          ;Cursor up, stop at top
tb:	db	'V'-64,'$',0,0          ;Cursor down, stop at bottom
tc:	db	'L'-64,'$',0,0          ;Cursor right, stop at right
td:	db	'H'-64,'$',0,0          ;Cursor left, stop at left
te:	db	'Z'-64,0,0,'$'          ;Clear display (2 pad nulls)
tf:	db	'$',0,0,0               ;(can't) Enter Graphics mode
tg:	db	'$',0,0,0               ;(can't) Exit Graphics mode
th:	db	1EH,'$',0,0             ;Cursor home
ti:	db	esc,'j$',0              ;Reverse linefeed, scroll
tj:	db	esc,'Y$',0              ;Clear to end of sreen
tk:	db	esc,'T$',0              ;Clear to end of line
ENDIF;tvi925
;
;

IF adm3a
defesc  EQU     '['-100O        ;Still Control-\ (just ran out of room...)
ttytyp:	db	'ADM3A$'
outlin:	db	'Z'-64,0,0,cr,lf,'$'
erascr:	db	'Z'-64,0,0,'$'          ;Clear screen and home
eralin:	db	esc,'Y$',0              ;Clear to end of sreen
curldn:	db	cr,esc,'=$'             ;Cursor lead-in
ttab:	;Table start location           ;(MUST be 4 bytes each)
ta:	db	'K'-64,'$',0,0          ;Cursor up, stop at top
tb:	db	'J'-64,'$',0,0          ;Cursor down CTRL-J
tc:	db	'L'-64,'$',0,0          ;Cursor right, stop at right
td:	db	'H'-64,'$',0,0          ;Cursor left, stop at left
te:	db	'Z'-64,0,0,'$'          ;Clear display (2 pad nulls)
tf:	db	'$',0,0,0               ;(can't) Enter Graphics mode
tg:	db	'$',0,0,0               ;(can't) Exit Graphics mode
th:	db	1EH,'$',0,0             ;Cursor home
ti:	db	'K'-64,'$',0,0          ;Reverse linefeed
tj:	db	'$',0,0,0               ;(can't) Clear to end of screen
tk:	db	'$',0,0,0               ;(can't) Clear to end of line
ENDIF;adm3a


IF smrtvd	; [7] new terminal
vtval	EQU	1		; we do VT52 emulation
defesc	EQU	'\'-100O	; escpae character, ok?
ttytyp:	db	'Smartvid-80$'
outlin:	db	esc,'+',cr,lf,tab,tab,'$'
eralin:	db	cr,esc,'T$'                     ;Clear to end of line.
erascr:	db	esc,'+$'                        ;Clear screen and go home.
curldn:	db	esc,'=$'                        ;Cursor lead-in
ttab:					;Table start location.
ta:	db	('K'-100O),'$',0,0      ;Cursor up.
tb:	db	12O,'$',0,0             ;Cursor down.
tc:	db	('A'-100O),'$',0,0      ;Cursor right.
td:	db	('H'-100O),'$',0,0      ;Cursor left.
te:	db	('L'-100O),'$',0,0      ;Clear screen and home cursor
tf:	db	'$',0,0,0               ;(can't) Enter Graphics mode
tg:	db	'$',0,0,0               ;(can't) Exit Graphics mode
th:	db	('Z'-100O),'$',0,0      ;Cursor home.
ti:	db	('K'-100O),'$',0,0      ;Reverse linefeed.
tj:	db	esc,'Y$',0              ;Clear to end of screen.
tk:	db	esc,'T$',0              ;Clear to end of line.
ENDIF;smrtvd

IF h1500
vtval	EQU	1		; we can do VT52 emulation
defesc	EQU	'\'-100O        ;Still Control-\ (just ran out of room...)
ttytyp:	db	'Hazeltine$'
outlin:	db	7eh,1ch,7eh,12h,'$'
erascr:	db	7eh,1ch,7eh,12h,'$'	;Clear screen and home
eralin:	db	7eh,13h,'$',0		;Clear to end of sreen
curldn:	db	7eh,11h,'$',0           ;Cursor lead-in
ttab:	;Table start location           ;(MUST be 4 bytes each)
ta:	db	7eh,0ch,'$',0		;Cursor up, stop at top
tb:	db	7eh,0bh,'$',0		;Cursor down CTRL-J
tc:	db	10h,'$',0,0		;Cursor right, stop at right
td:	db	8h,'$',0,0		;Cursor left, stop at left
te:	db	7eh,1ch,'$',0		;Clear display (2 pad nulls)
tf:	db	'$',0,0,0               ;(can't) Enter Graphics mode
tg:	db	'$',0,0,0               ;(can't) Exit Graphics mode
th:	db	7eh,0ch,'$',0		;Cursor home
ti:	db	7eh,0ch,'$',0		;Reverse linefeed
tj:	db	'$',0,0,0               ;(can't) Clear to end of screen
tk:	db	7eh,0fh,'$',0		;Clear to end of line
ENDIF;h1500

IF wyse ;[gv]
vtval	equ	1		; we can do VT52 emulation
defesc	EQU	'\'		;Still Control-\ (just ran out of room...)
ttytyp:	db	' [Wyse 100]',cr,lf,'$'
outlin: db      esc,'+$',0              ;Clear screen and home
erascr: db      esc,'+$',0              ;Clear screen and home
eralin: db      esc,'Y$',0              ;Clear to end of sreen
curldn: db      cr,esc,'=$'             ;Cursor lead-in
ttab:   ;Table start location           ;(MUST be 4 bytes each)
ta:     db      03h,'$',0,0             ;Cursor up, stop at top
tb:     db      lf,'$',0,0              ;Cursor down, stop at bottom
tc:     db      ff,'$',0,0              ;Cursor right, stop at right
td:     db      bs,'$',0,0              ;Cursor left, stop at left
te:     db      sub,0,0,'$'             ;Clear display (2 pad nulls)
tf:     db      '$',0,0,0               ;Enter Graphics mode NONE
tg:     db      '$',0,0,0               ;Exit Graphics mode NONE
th:     db      1eh,'$',0,0             ;Cursor home
ti:     db      esc,'v$',0              ;Reverse linefeed, scroll ???
tj:     db      esc,'Y$',0              ;Clear to end of sreen
tk:     db      esc,'T$',0              ;Clear to end of line
ENDIF;wyse



ovlend	equ	$	; End of overlay

IF lasm		;Not really needed, as M80 ignores END in include files
	END
ENDIF	;lasm
