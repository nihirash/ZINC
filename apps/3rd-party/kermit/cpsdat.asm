; CPSDAT.ASM
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
;       Pure and impure data areas. Previously of CPSUTL.ASM
;
; revision history:
;
;edit 19, 29-Mar-1991 by MF. Add flag "initak" (nonzero) which is cleared
;	after the initial automatic TAKE attempt of KERMIT.INI to allow
;	"unable to find file" complaints if not doing that initial TAKE.
;edit 18, 21-Mar-1991 by MF. Renamed parameter vermin to revno (revision
;	level) since verno is already known as the "minor version number".
;edit 17, 27-Feb-1991 by MF. Corrected typeo in "inms19" and commented out
;	"typptr" pointer as the TYPE command now uses the big buffer.
;	Also provided for a "minor version number" (1-26=A-Z) and message to
;	facilitate display of Kermit version in VERSION command (modmsg)
;edit 16, 12-Feb-1991 by MF. Eliminated storage (message and variable)
;	for case sensitivity by commenting it out.
;edit 15, 9-Dec-1990 by MF. Modified message for "directory file size"
;	status report to make it clearer when spoken by a speech synthesizer.
;edit 14, 4-Dec-1990 by MF. Added message for Autoreceive status report.
;edit 13, 30-Nov-1990 by MF. Added messages to display regular/quiet status
;	of terminal in SHOW and STATUS commands.
;edit 12, 8-Nov-1990 by MF.  Added a new message for Set Autoreceive.
;edit 11, 2-Nov-1990 by MF.  Moved overlay address to 7000H -- I didn't
;	realize I was **that** close to the limit until I made a couple of
;	cosmetic changes and REM CD bombed.  This is still ver. 4.10 as it
;	hasn''t been released yet.
;edit 10, 1-Nov-1990 by MF.  Changed message at "spdst" to conform with
;	the change of "SET BAUD-RATE" to "SET SPEED".
;	Also added message "sdpst2" for speed status (staspd) routine
;edit 9, 17-Oct-1990 by MF.  Changed "packet-size" messages to use the
;	word "length" to conform with the nomenclature suggested in the
;	6th edition of the Kermit Protocol Manual.
;edit 8, 19-Sep-1990 by MF.  Added error message for FRENAME command.
;edit 7, 14-Sep-1990 by MF.  Added storage/strings for SET COLLISION command.
;	Also added strings/storage for SET INCOMPLETE-FILE command.
;edit 6, 9-Sep-1990 by MF.  Added messages and storage for Remote commands.
;	and display of packet sizes
;	Moved overlay address to 06C00H for Version 4.10.
; edit 5, 8 April, 1987 by OBSchou.  Added new entry in jump table to call 
;	code for an external terminal type.  Added some new error messages
;	and added more to the packet space.
;
; edit 4, 30 March by OBSchou.  Added in space for autoreceive.
;
; edit 3, 19 March, 1987 by OBSchou.  Added some more strings etc, and 
;	increased the stack space fro 32 entries to 64.
;
; edit 2, 11 March, 1987 by OBSchou. 
;	Added in some more data and strings and things.  Nothing special
;
; edit 1, 28 January, 1987 by OBSchou
;	Following file the data section of CPSUTL.ASM.  This part of the 
;	CPSUTL.ASM file now seperate as it ws getting too larg.  Link to here
;	from CPSUTL.ASM (which now has only the utlity routines). 
;	Also added in bits submitted by Dave Roberts of Leicester:
;	 DJR  18th January 1987 - David J. Roberts.
;           Support for cosmetic changes in CPSMIT:
;              New strings DBGST and CURDST
;              CRLF in front of TIMMSG
;              LOGST changed, and new LOGST2
;
;
datver:	db	'CPSDAT.ASM (19)  29-Mar-1991$'



;

version:db	'Kermit-80 v4.'
	db	(verno/10) + '0'        ; tenth's digit of version number
	db	(verno MOD 10) + '0'    ; hundredth's digit
IF revno			;[MF]If a revision level,
	db	revno+'@'	;[MF]put it in (range 1-26=A-Z)
ENDIF ;revno [MF]
	db	' $'
modmsg:	db	' has been built from the following modules:$';[MF]
kerm:	db	'Kermit-80  '
kerm1:	db	'nnx:>$'        ;'x' filled in at startup with DRIVE name
				;'nn filled at startup and user with user number
crlf:	db	cr,lf,'$'
ermes1:	db	cr,lf,'?Unrecognized command$'
ermes3:	db	cr,lf,'?Not confirmed$'
ermes4:	db	'?Unable to receive initiate',cr,lf,'$'
ermes5:	db	'?Unable to receive file name',cr,lf,'$'
ermes6:	db	'?Unable to receive end of file',cr,lf,'$'
erms10:	db	'?Unable to receive data',cr,lf,'$'
erms11:	db	'?Disk full',cr,lf,'$'
erms12:	db	'?Directory full',cr,lf,'$'
erms14:	db	'?Unable to receive an acknowledgement from the host',cr,lf,'$'
erms15:	db	cr,lf,'?Unable to find file',cr,lf,'$'
erms16:	db	'?Unable to rename file$'
erms17:	db	cr,lf,'?Disk full$'
erms18:	db	cr,lf,'?Unable to tell host that the session is finished$'
erms19:	db	cr,lf,'?Unable to tell host to logout$'
erms20:	db	cr,lf,'?Kermit has not been configured for a target system$'
erms21:	db	cr,lf,'?Consistency check on configuration failed$'
erms22:	db	cr,lf,'?Error writing to log file',cr,lf,'$'    ;[pcc005]
erms23:	db	cr,lf,'?Invalid user number$'
erms24:	db	cr,lf,'?Invalid Pause parameter$'
erms25:	db	cr,lf,'?Invalid BUFFER-SIZE parameter$'
erms26:	db	cr,lf,'?Invalid packet length (too long)$'
erms27:	db	cr,lf,'?Invalid Checktype$'
erms28:	db	cr,lf,'?Too many retries$'
erms29:	db	cr,lf,'?Failed to exchange parameters$'
erms30:	db	cr,lf,'?Failed to receive input string in alloted time$'
erms31:	db	cr,lf,'?File already exists$' ;[MF]

infms3:	db	bell,'Completed$'
infms4:	db	bell,'Failed$'
infms5:	db	'%Renaming file to $'
infms6:	db	cr,lf,'[Closing the log file]$'
infms7:	db	cr,lf,'[Connected to remote host.  Type $'
infms8:	db	'C to return;',cr,lf,' type $'
inms8a:	db	'? for command list]',cr,lf,'$'
infms9:	db	cr,lf,'[Connection closed, back at micro]$'
inms10:	db	'Control-$'
inms11:	db	' Not implemented.$'
inms12:	db	' (Not implemented)',cr,lf,'$'
inms13:	db	bell,'Interrupted$'
inms14:	db	TAB,TAB,'    Directory for drive '
dnam14:	db	'nnx:',cr,lf,'$'                ;filled in by dir routine.
inms15:	DB	CR,LF,TAB,TAB,'Drive $'
inms16:	DB	'  has $';filled in by summary code with drive letter
inms17:	DB	'K bytes free',CR,LF,'$'
inms18:	DB	CR,LF,'File(s) erased$',CR,LF
inms19:	db	cr,lf,'[Transmitting file to host:'
	db	cr,lf,' 1. Lines automatically sent, and wait for possible reply'
	db	cr,lf,' 2. CONTROL-C aborts transfer'
	db	cr,lf,' 3. If transfer hangs, try a return to continue'
	db	cr,lf,' 4. on exit, you will be placed in CONNECT state.'
	db	cr,lf,'$'
inms20:	db	'R to send the same line again,'
	db	cr,lf,'   or type $'
inms21:	db	'C to abort transmission.]',cr,lf,'$'
inms22:	db	cr,lf,'[Transmission done. Connected normally '
	db	'to remote host,'
	db	cr,lf,' type $'
inms23:	db	'Sending...$'
inms24:	db	'Receiving...$'
inms25:	db	bell,'Warning: eighth bit cannot be sent$'
inms26:	db	cr,lf,'For help, type ? at any point in a command$'
inms27:	db	cr,lf,'[Logging suspended]',cr,lf,'$'   ;[pcc003]
inms28:	db	cr,lf,'[Logging resumed]',cr,lf,'$'     ;[pcc003]
inms29:	db	cr,lf,'[Transmission Aborted. Connected normally '
	db	'to remote host,'
	db	cr,lf,' type $'
autmes:	db	cr,lf,cr,lf,'[Automatically receiving; type ^C to abort]'
	db	cr,lf,cr,lf,'$'	;[MF]
anymes:	db	cr,lf,cr,lf,' * * * Press any key to continue * * * '
	db	cr,lf,cr,lf,'$'
escmes:	db	cr,lf,'Type the new escape character:  $'
tacmes:	db	cr,lf,'Type the new TAC intercept character:  $'
sopmes:	db	cr,lf,'Give the start-of-packet character: $'	;[gnn]
padcms:	db	cr,lf,'Type the new padding character: $'	;[obs]
xmthlp:	db	cr,lf,'R Send the same line again$'
loghlp:	db	cr,lf,'Q  Suspend logging'              ;[pcc003]
	db	cr,lf,'R  Resume logging$'              ;[pcc003]
inthlp:	db	cr,lf,'?  This message'
	db	cr,lf,'C  Close the connection'
	db	cr,lf,'0  (zero) Transmit a NULL'
	db	cr,lf,'P  Toggle printer on/off'        ;[pcc002]
	db	cr,lf,'S  Status of the connection$'
inhlp1:	db	cr,lf,'Typing another $'
inhlp2:	db	' will send it to the host'
	db	cr,lf,cr,lf,'Command>$'

xmtst:	db	cr,lf,'Transmitting a file$'
autrst:	db	cr,lf,'Autoreceive is$'
locst:	db	cr,lf,'Local echo$'
onstr:	db	' on$'
offstr:	db	' off$'
flost:	db	cr,lf,'Flow control$'
;senst:	db	cr,lf,'Case sensetivity$'
vtdpst:	db	cr,lf,'Terminal display is $'
vtdpsr:	db	'REGULAR$'
vtdpsq:	db	'QUIET$'
vtemst:	db	cr,lf,'Terminal emulation is $'
cpmst:	db	cr,lf,'File Mode$'
defstr:	db	' default$'
ascstr:	db	' ASCII$'
binstr:	db	' binary$'
hfsod:	db	cr,lf,'Display file size on DIRECTORY command$'
ibmst:	db	cr,lf,'IBM flag$'
incst:	db	cr,lf,'Disposition for incomplete files is$'
dscstr:	db	' discard$'
kepstr:	db	' keep$'
filst:	db	cr,lf,'File warning$'
prst:	db	cr,lf,'Printer copy$'
logst:	db	cr,lf,'Logging to $'		;[pcc003][DJR]
logst2:	db	' is$'				;[DJR]
susstr:	db	' suspended$'                   ;[pcc003]
sspmsg:	db	cr,lf,'SEND start-of-pkt char  ^$' ;[gnn]
rspmsg:	db	cr,lf,'RECEIVE start-of-pkt char  ^$' ;[gnn]
spsmsg:	db	cr,lf,'SEND packet length  $' ;[MF]
rpsmsg:	db	cr,lf,'RECEIVE packet length  $' ;[MF]
escst:	db	cr,lf,'Escape char: $'
bufsz1:	db	cr,lf,'Multi-sector buffering at $'
bufsz2:	db	' of a maximum of $'
xmitst:	db	cr,lf,'Transmit protocol char: $'
bckst:	db	cr,lf,'Block check type: $'
bckst1:	db	'-character$'
collst:	db	cr,lf,'File COLLISION:  $';[MF]
parst:	db	cr,lf,'Parity: $'
pnonst:	db	'none$'
pmrkst:	db	'mark$'
pspcst:	db	'space$'
poddst:	db	'odd$'
pevnst:	db	'even$'
porst:	db	cr,lf,'Port in use is: $'
spdst:	db	cr,lf,'Current speed is: $'
spdst2:	db	' bps$'		;[MF]
spdust:	db	'indeterminate (not SET)$'
timmsg:	db	cr,lf,'Timer$'			;[DJR] Added CRLF like the others
tacst:	db	cr,lf,'Current TACTrap Status/Intercept Character:  $'
usrst:	db	cr,lf,'Current user number:  $'
dbgst:	db	cr,lf,'Debugging$'		;[DJR]
curdst:	db	cr,lf,'Current default disk: $'	;[DJR]
spac15:	db	'               $'              ; *** 15 spaces ***
samems:	db	cr,lf,'?Source and destination files the same$'
nofile:	db	cr,lf,'?File not found$'
cmer00:	db	cr,lf,'?Program error:  Invalid COMND call$'
cmer01:	db	cr,lf,'?Ambiguous$'
cmer02:	db	cr,lf,'?Illegal CP/M file specification$'
cmer03:	db	cr,lf,'?Wild-cards not allowed in file specification$'  ;[pcc006]
cmer04:	db	cr,lf,'?Invalid user number$'
cmer05:	db	cr,lf,'?Invalid \ parameter$'
cmin00:	db	' Confirm with carriage return$'
cmin01:	db	' Enter a number$'
cmin02:	db	' Confirm with carriage return or enter more$'

;  Diagnostic messages
sstatm:	db	'<SState:> ',0
rstatm:	db	'<RState:> ',0
spackm:	db	'<Data transmitted> ',0
rpackm:	db	'<Data received   > ',0
princr:	db	cr,lf,0
;
; Remote command messages [MF]
;
newfms:	db	cr,lf,'New file: $'
pswdms:	db	cr,lf,'Password: $'
acctms:	db	cr,lf,'Account: $'
newnms:	db	cr,lf,'New name: $'
msgms:	db	cr,lf,'Message: $'
optms:	db	cr,lf,'Options: $'

;
	;Impure data

;COMND storage

comchr:	ds	1		;[8] save space
floctl:	db	0		;[8] flow control on/off flag
;casens:	db	0		;[8] Upper/lower case sensitive
cmstat:	ds	1		;What is presently being parsed.
cmaflg:	ds	1		;Non-zero when an action char has been found.
cmbflg:	ds	1		;[MF]Nonzero to allow a blank initial keyword
cmqflg:	ds	1		;[MF]Nonzero to prevent character echoing
				;[MF]when entering commands
cmccnt:	ds	1		;Non-zero if a significant char is found.
cmsflg:	ds	1		;Non-zero when the last char was a space.
cmostp:	ds	2		;Old stack pointer for reparse.
cmrprs:	ds	2		;Address to go to on reparse.
cmprmp:	ds	2		;Address of prompt.
cmptab:	ds	2		;Address of present keyword table.
cmhlp:	ds	2		;Address of present help.
cmdbuf:	ds	80H		;Buffer for command parsing.
cmbufl	equ	$-cmdbuf-3	; set a limit on the command buffer
cmfcb:	ds	2		;Pointer to FCB.
cmfcb2:	ds	2		;Pointer to position in FCB.
cmfwld:	ds	1		;Wildcard flag
cmcptr:	ds	2		;Pointer for next char input.
cmdptr:	ds	2		;Pointer into the command buffer.
cmkptr:	ds	2		;Pointer to keyword.
cmsptr:	ds	2		;Place to save a pointer.
slshsn:	db	0		; slash seen in command line
slashc:	db	0		; count for number of characters in slash sequence
slashn:	db	0		; number to be built for \xxx
;
oldsp:	ds	2		;Room for old system stack.
	ds	80H		;Room for 64 levels of calls.[obs]
stack:	ds	2
eoflag:	ds	1		;EOF flag;non-zero on EOF.
curdsk:	db	0		;holds "logged" disk
curusr:	db	0		;[8] holds "user" number
rcvsop:	db	SOH		;[gnn] receive start-of-packet
sndsop:	db	SOH		;[gnn] send start-of-packet
prtcnt:	db	0		;[pcc008] prtchr fairness count
timflg:	db	0		;[jd] timer flag: 0 -> no timer
timval:	dw	0		;[jd] timer value
wrn8:	db	0		;[jd] non-zero if 8-bit-lost warning sent
qbchr:	db	'&'             ;[jd] binary quote character.
quot8:	db	0		;[jd] non-zero if doing 8-bit quoting
logflg:	db	0		;Flag for a log file.
				;[pcc005] 0 = no log
				;[pcc005] x1 = logging on
				;[pcc005] x2 = suspended
				;[pcc005] 8xH (bit 7) = file open
lognam:	db	0		;[pcc013] File to use for session logging
	db	'KERMIT  '      ;[pcc013]
	db	'LOG'           ;[pcc013]
nexitf:	db	0		; set to 1 for exit to CPM after command tail
takflg:	db	0		;[8] TAKE flag. 
				; Bit zero = 1 for take file in progress
				; bit 4 = 1 if command line present/in progress
				; Note: Take has priority over command line.
initak:	db	0ffh		;[MF]Cleared after initial TAKE (KERMIT.INI)
taknam:	db	0		;[8] use default drive
	db	'KERMIT  '
	db	'INI'           ;[8] Inital file to TAKE KERMIT.INI
takptr:	ds	2		;[8] Pointer to position in TAKE file input
takfcb:	ds	12		;[8] fcb space for take file
	dw	0		;[8] fill up extents etc with 00
	dw	0
	ds	16		;[8] used by dos
	dw	0
	dw	0
takdma:	ds	128		;[8]space to read TAKE file...
prnbuf:	ds	1		; printer buffer. Output pointer
	ds	1		; input offset pointer
	ds	256		; give a large buffer
	ds	10		; and a little spare
;
;
;
; Transmit space
;
repcnt:	db	0		; repeat counter
starc:	db	0		; star count
rexbfl:	db	0		; retransmit flag (1=> retransmit)
rexcnt:	db	0		; retransmit character count
rexbuf:	ds	128		; max retransmit line length 128 characters
xmtbuff:
	ds	128		; 128 byte sector buffer
xmtptr:	db	0		; offset pointer to xmtbuff above
xmtfcb:	ds	36		; fcb for transmit file.
;
;INPUT and STRING space
strlen:	db	0		; length of the string from INPUT and STRING

; Assorted other space
errorc:	db	0		; error level set to xxx
errorl:	db	0		; error level to test against

remtxt:	db	0		; set <> 0 if D packets to screen

hosths:	ds	1		; have we told the host to xoff? (is this duplicated)
stbuff:	ds	80h		; some space or the string buffer
waitp:	ds	2		; wait command timer
waitp1:	ds	2		; wait/input timer (copy of waitp)
prntmp:	ds	1		; temporary space to put the caracter to print
prnfl:	db	0		; printer flag.  Used by TYPE/PRINT
;[MF][17]Following line no longer needed as TYPE uses the big buffer
;typptr:	ds	2		; pointer used by TYPE/PRINT
equflg:	db	0		; set to non zero if copy files same
nquiet:	db	0		; If non zero print from NOUT to display

escflg:	db	0		;Escape flag (start off).
fileio:	db	0		;Line-by-line from file (default off).
xofflg:	db	0		;X-OFF (=^S) received from COMM-line
				;X-ON (=^Q) received resets this
clkbit:	dw	0		; 32 bit pseudo clock
	dw	0		; MS bits of clock
number:	ds	2		; Number in binary form from user input
initflg:db	0		; set to non zero when system initialised
maxbsc:	ds	1		; save space to know how big system allows
				; for multi-sector buffering. (Usually 8k?)
;
;       Multiple FCB storage space.  Used for the DIR command
;               Later on, I want to shift this into space after the system
;               dependent stuff, but then it becomes messy with pointers
;               to pointers etc... [OBS]
;
xfcbptr:
	ds	2		; pointer to current fcb space
fcbcnt:	ds	1		; Number of valid fcbs in space
;
fcb0:	ds	12		; 36 bytes requred for a single fcb
fcblen	EQU	$-fcb0		; length of a single fcb
	ds	maxfcb*fcblen	; space for maximum fcbs + 1 
;
hidefs:	db	0ffh		; flag <> 0 if we show file size in DIR

; FCB sapce for COPY command
cfcbs:	ds	33		; source fcb for copy file ops.
				;[MF]and FRENAME ops.
cfcbd:	ds	33		; destination fcb for copy ops.
				;[MF]and FRENAME ops.

colfcb:	ds	33		;[MF]Rename fcb for SET COLLISION

; Command tail data space etc
cbptr:	db	2		; command tail pointer (0= length of tail)
cbuff:	ds	128		; temp. space for potential command tail

strcnt:	db	0		; string count for string operations...

vtyval:	ds	1		; holds row number for VT52 cursor positioning
chrcnt:	ds	1		;Number of chars in the file buffer.

; Various packet variables etc
bytes:	dw	0		; 4 byte 'byte count' space
	dw	0
filcnt:	ds	1		;Number of chars left to fill.
outpnt:	ds	2		;Position in packet.
bufpnt:	ds	2		;Position in file buffer.
fcbptr:	ds	2		;Position in FCB.
datptr:	ds	2		;Position in packet data buffer.
cbfptr:	ds	2		;Position in character buffer.
pktptr:	ds	2		;Position in receive packet.
size:	ds	1		;Size of data from gtchr.
curchk:	ds	1		;Current checksum type
inichk:	ds	1		;Agreed upon checksum type
czseen:	ds	1		;Flag that control-Z was typed
dscflg:	ds	1		;[MF]Discard file if nonzero
pktnum:	ds	1		;Packet number.
numpkt:	ds	2		;Total number of packets sent.
numrtr:	ds	2		;Total number of retries.
numtry:	ds	1		;Number of tries on this packet.
oldtry:	ds	1		;Number of tries on previous packet.
state:	ds	1		;Present state of the automaton.
;*** start of new flags.  Do not assume that just because these flags are
;  present that the feature is available.  I simply put them in 'for future use'
rcapas:
rcap1:	db	0		; receive capabilties byte 0
rcap2:	db	0		; receive cpabilities byte 1
scapas:
scap1:	db	0		; send capabilities byte 0
scap2:	db	0		; send capabilities byte 1
rtimeo:	db	0		; receive timeout
stimeo:	db	0		; send timeout
rpadc:	db	0		; receive pad character
spadc:	db	0		; send pad character
rrept:	db	0		; receive repeat prefix
srept:	db	0		; send repeat prefix
rwindo:	db	0		; receive window size
swindo:	db	0		; send window size
rdpkt:
rlpkt:	dw	0		; receive long packet length
sdpkt:
slpkt:	dw	0		; send long packet length
sdckt:	db	0		; send default checktype
rdckt:	db	0		; receive checktype (should be same as sdckt)
;*** end  of new flags
sohchr:	db	1		;Default Start-of-header chr is cntl-a
; Kermit packet starts here
;	Byte 0 = start of packe character
;	     1 = length of packet
;	     2 = packet number
;	     3 = packet type (S R I Z E B etc)
packet:	ds	4		;Packet (data is part of it).
; Data part of packet (variable length - include checksum)
data:	ds	5AH		;Data and checksum field of packet.
recpkt:	ds	65H		;Receive packet storage (use the following).
recpkx:	db	cr,'$'          ;=      =       = buffer limit
filbuf:	ds	65H		;Character buffer.
fnbuf:	ds	20h		;[jd] file name buffer
autorc:	db	0		;[obs] set to ON for autoreceive

; Temporary data space.  Sometimes accesses as 16 bits (eg temp1/2)
;** Temp 1 & 2 must be in order
lstchr:				;Last console input character.
temp1:	ds	1		;Temporary storage.
temp2:	ds	1
lincnt:				; used for counting lines in p20ln
temp3:	ds	1
temp4:	ds	1
temp5:	ds	1
temp6:	ds	1
temp7:	ds	1
temp8:	ds	1
temp9:	ds	1
temp10:	ds	1
temp11:	ds	1


getrxflg:
	ds	1		;[obs 22]
quietd:	db	0		;loud display during file transfers
argblk:	ds	20H		;Used for subroutine arguments

maxfil	EQU	2		; currently, only two names used.
fcbblk:	ds	maxfil*10H	;Used for a list of FCB's

; [gnn] secondary filename storage (remote on send, local on get)
remnam:	ds	60		;[gnn]
remlen:	ds	1		;[gnn] length of name

; Bookkeeping storage for multiple-sector buffering.  The actual buffer
; is somewhere in the system-dependent overlay. (at the end, I hope).
nxtbuf:	ds	2		; Pointer to next sector
seccnt:	ds	1		; Number of sectors buffered
endsts:	ds	1		; Status for last read into buffer
;
;
; [MF] Storage for Remote Command processing
;
;
rdl:	ds	1		;[MF]Holds accumulated length of remote data
;
rcl:	ds	1		;[MF]Holds length of Remote command line arg
;
remdat:	ds	95		;[MF]Packet data buffer (plenty big)
;
rcom:	ds	1		;[MF] Remote Command type
;
rprmpt:	dw	0		;[MF]Address of prompt strings
;
rptr:	dw	0		;[MF]Remote command packet data pointer
;
rscode:	ds	3		;[MF]Holds Remote Set command ASCII code
;
;
	org	7000h		; address for Kermit 4.11
;               ORG     ($ + 0ffH) AND 0ff00H   ; move to start of next page

;
;       hooks for system-dependent routines:
;       This area is overwritten by the system-dependent overlay.
;
lnkflg:	dw	0	; linkage information for consistency check.
lnkent:	dw	0	; more of the same.
ovlver:	dw	0	; pointer to overlay's version string
family:	dw	0	;*NEW* [10] address of the family overlay (not CPSSYS)
;
; Input/output routines.  Note that outmdm and outcon may actually be the
;       same routine if selmdm and selcon do anything.  (the same is true
;       of inpmdm and inpcon).
;
selmdm:	jmp	$-$	; select modem for I/O
outmdm:	jmp	$-$	; output character in E to modem
inpmdm:	jmp	$-$	; read character from modem. return character or 0 in A.
flsmdm:	jmp	$-$	; flush pending input from modem
selcon:	jmp	$-$	; select console for I/O
outcon:	jmp	$-$	; output character in E to console
inpcon:	jmp	$-$	; read char from console. return character or 0 in A
outlpt:	jmp	$-$	; output character in E to printer
lptstat:jmp	$-$	;*NEW*[10] see if printer ready to print a character
			; If 0ffh then ok, if 0h then not ok.
extern:	jmp	$-$	;*NEW for 4.09* If $-$ is not zero, then its a jump to
			; a routine to emulate any terminal type the user
			; wants to implement.
xbdos:	jmp	0	;*NEW* address of the bdos trap in this section
			; of code.  It is filled in initialisation.
;
; screen formatting routines
clrlin:	jmp	$-$	; erase current line
clrspc:	jmp	$-$	; erase current position (after backspace)
delchr:	jmp	$-$	; make delete look like backspace
clrtop:	jmp	$-$	; erase screen and go home
;
; these routines are called to display a field on the screen.
scrend:	jmp	$-$	; move to prompt field
screrr:	jmp	$-$	; move to error message field
scrfln:	jmp	$-$	; move to filename field
scrnp:	jmp	$-$	; move to packet count field
scrnrt:	jmp	$-$	; move to retry count field
scrst:	jmp	$-$	; move to status field
rppos:	jmp	$-$	; move to receive packet field (debug)
sppos:	jmp	$-$	; move to send packet field (debug)
;
sysinit: jmp	$-$	; program initialization
sysexit: jmp	$-$	; program termination
syscon:	jmp	$-$	; remote session initialization
syscls:	jmp	$-$	; return to local command level
sysinh:	jmp	$-$	; help text for interrupt (escape) extensions
sysint:	jmp	$-$	; interrupt (escape) extensions, including break
sysflt:	jmp	$-$	; filter for incoming characters.
			;  called with character in E.
sysbye:	jmp	$-$	; terminate remote session
sysspd:	jmp	$-$	; baud rate change routine.
			; called with value from table in DE
sysprt:	jmp	$-$	; port change routine.
			; called with value from table in HL
sysscr:	jmp	$-$	; screen setup for file transfer
			; called with Kermit's version string in DE
csrpos:	jmp	$-$	; move cursor to row B, column C
sysspc:	jmp	$-$	; calculate free space for current disk
mover:	jmp	$-$	; block move
prtstr:	jmp	$-$	; *** NEW *** prtstr moved to overlay
;
; Data initialized by system-dependent overlay:
;
pttab:	ds	2	; points to local equivalents to VT52 escape sequences
spdtab:	ds	2	; address of baud rate command table, or zero
spdhlp:	ds	2	; address of baud rate help table, or zero
prttab:	ds	2	; address of port command table, or zero
prthlp:	ds	2	; address of port help table, or zero
timout:	ds	2	; Initial value for fuzzy timeout
vtflg:	ds	1	; VT52 emulation flag
escchr:	ds	1	; Storage for the escape character.
speed:	ds	2	; storage for the baud rate
port:	ds	2	; storage for port value
prnflg:	ds	1	;[hh] printer copy flag (overlay may need it)
dbgflg:	ds	1	; debugging flag
ecoflg:	ds	1	; Local echo flag (default off).
flwflg:	ds	1	; File warning flag (default on).
ibmflg:	ds	1	; IBM flag (default off).
cpmflg:	ds	1	; File mode flag (ascii/binary/default)
incflg:	ds	1		;[MF]Incomplete flag (keep/discard)
				;[MF](default discard)
parity:	ds	1	; Current parity.
spsiz:	ds	1	; Send packet size.
rpsiz:	ds	1	; Receive packet size.
stime:	ds	1	; Send time out.
rtime:	ds	1	; Receive time out.
spad:	ds	1	; Send padding.
rpad:	ds	1	; Receive padding.
spadch:	ds	1	; Send padding char.
rpadch:	ds	1	; Receive padding char.
seol:	ds	1	; Send EOL char.
reol:	ds	1	; Receive EOL char.
squote:	ds	1	; Send quote char.
rquote:	ds	1	; Receive quote char.
chktyp:	ds	1	; Checksum type desired
tacflg:	ds	1	; TACTrap flag (zero=off, nonzero=on; when non-zero,
			;  contains current TAC intercept character)
tacchr:	ds	1	; TAC intercept character
bufadr:	ds	2	; Pointer to big buffer for multiple-sector I/O
bufsec:	ds	1	; Number of sectors big buffer can hold (0 means 256)
ffussy:	ds	1	; if nonzero, don't permit <>.,;?*[] in CP/M filespec.
; space used by directory command; here because space calculation is
;  (operating) system-dependent
bmax:	ds	2	; highest block number on drive
bmask:	ds	1	; (records/block)-1
bshiftf: ds	1	; number of shifts to multiply by rec/block
nnams:	ds	1	; counter for filenames per line

lnksiz	equ	$-lnkflg ; length of linkage section, for consistency check.

	END	START
