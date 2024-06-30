; CPSWLD.ASM
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
;       Multi-file access subroutine.  Allows processing of multiple files
;       (i.e., *.ASM) from disk.  This routine builds the proper name in the
;       FCB each time it is called.  This command would be used in such pro-
;       grams such as modem transfer, tape save, etc. in which you want to
;       process single or multiple files.
;       Note that it will fail if more than 256 entries match the wildcard.
;
; revision history:
; edit 4: June 20, 1986, by OBSchou.  Added stuff at top and tail of routine
;       to support multiple FCBs.  If the routine get to mfn01 (Search for next)
;       then the next file found gets its fcb added to the buffer.  Once no 
;       more files have been found, the mfflg3 flag is set non-zero. 
;       The first thing to test on entry is whether a disk access
;       is needed.  Either way, the routine should return the next file name
;       in the fcb, or return with the carry flag set if there are no more
;       files to do.  Once there is a carry flag set for the return, all 
;       temporary flags are reset. Get all that?
;
; edit 3: July 27, 1984
;       support LASM: remove exclamation points, link to CP4CMD.
;
; edit 2: June 7, 1984 (CJC)
;       formatting and documentation; add module version string; redo movfcb,
;       in preparation for moving DMA buffer (later...).
;
; edit 1: May, 1984 (CJC)
;       extracted from CPMBASE.M80 version 3.9; modifications are described
;       in the accompanying .UPD file.
;
wldver:	db	'CPSWLD.ASM (4)  20-Jun-86$'

;       The FCB will be set up with the next name, ready to do normal 
;       processing (OPEN, READ, etc.) when routine is called.
;
;       Carry is set if no more names can be found
;
;       MFFLG1 is count/switch [0 for first time thru, pos for all others]
;       MFFLG2 is counted down for each successive GETNEXT file call
;       MFFLG3 is set to the last remaining FCBs buffered once Search for next
;               file fails with files in the buffer.
;
;       Technique used is to repeat SFIRST/SNEXT sequence N+1 times for each
;       successive call, till sequence fails. CP/M does NOT allow disk-handling
;       between SFIRST and SNEXT.
;       called by: send, seof, dir

mfname:	ora	a		; clear carry
	push	b		;Save registers
	push	d
	push	h
	jmp	mfnam0		; skip over the next bit (which is entered from elsewhere)

;[4] Get the FCB counter and see if we have any fcbs already.
mfnam1:	lxi	h,fcb0
	shld	xfcbptr		; reset the pointer if we are to return an FCB

mfnam0:	lda	fcbcnt
	ana	a		; if none, then we may have to get some from disk
	jz	mfn00		; see later on
	lhld	xfcbptr		; we have some, so give the next one to the user
	lxi	d,fcb		; move from (hl) to (de) for length bc
	lxi	b,12
	call	mover
	xra	a
	sta	fcbext		; clear fcb extents and such
	sta	fcbrno		; like record number
	lhld	xfcbptr		; point to next fcb
	lxi	d,fcblen
	dad	d		; yup
	shld	xfcbptr
	lda	fcbcnt
	dcr	a
	sta	fcbcnt		; decrease the number of fcbs we have
	xra	a		; clear carry
	jmp	mffix1		; and exit as if were all done

mfn00:	lda	mfflg3		; no more FCBs for the user, any more on disk?
	ana	a
	jnz	mffix2		; no, then set the carry flag to say so.
	lxi	h,fcb0		; now reset the fcb pointers and counter
	shld	xfcbptr
	xra	a
	sta	fcbcnt
;[4] end of this addition.  See below as well.


	mvi	c,setdma	;Init DMA addr, FCB
	lxi	d,80H
	call	bdos
	xra	a		;A = 0
	sta	fcbext		;clear extension
	lda	mfflg1		;find out if "second" call in row
	ora	a
	jnz	mfn01		;Were here before
	sta	mfflg2
	lxi	h,fcb
	lxi	d,mfreq
	lxi	b,12
	call	mover		;.from FCB to MFREQ
	mvi	c,SFIRST	;Search first
	lxi	d,fcb
	call	bdos
	jmp	mfn02		;and check results

mfn01:	dcr	a
	sta	mfflg2		;store down-counter
	lxi	h,mfreq		;SFIRST REQ name
	lxi	d,fcb
	lxi	b,12
	call	mover		;.from MFREQ to FCB
	mvi	c,sfirst	;Search first old one,we got it before
	lxi	d,fcb
	call	bdos		;no error's expected -we got that before
mfn01a:
	mvi	c,snext		;Search next
	call	bdos
mfn02:	push	psw
	lda	mfflg2		;get "repeat file counter"
	ora	a
	jz	mfn02a		;if zero, check if SNEXT had ERROR
	dcr	a		;count down
	sta	mfflg2		;store back
	pop	psw		;no error-check, we got it before
	jmp	mfn01a		;next SNEXT

mfn02a:	pop	psw
	ora	a
	jm	mffi2a		;No (more) found
	call	movfcb		;move data to fcb
	lda	mfreq		;the original disk-designator
	sta	fcb		;back into fcb
	lda	mfflg1		;get file-flag
	inr	a		;increment
	sta	mfflg1		;and store for next go-around
	mvi	a,0		;Setup FCB
	sta	fcbext		;clean up FCB for OPEN etc
	sta	fcbrno
	lhld	xfcbptr		;[4] like here 
	xchg
	lxi	h,fcb		;[4] from fcb space
	lxi	b,12
	call	mover
	lhld	xfcbptr		;[4] now lets update the pointers
	lxi	d,fcblen
	dad	d
	shld	xfcbptr		;[4] new pointer
	lda	fcbcnt		;[4] now the fcb counter
	inr	a
	sta	fcbcnt
	cpi	maxfcb		;[4] any more spare space?
	jp	mfnam1		;[4] nope, so get first fcb and return
	lxi	d,fcb		; else restore the file to serach for
	lxi	h,mfreq
	lxi	b,12		; copy the original fcb to fcb
	call	mover
	jmp	mfn01a		; and look for next match.

mffix1:	pop	h		;restore registers
	pop	d
	pop	b
	ret			;and return

mffi2a:
	sta	mfflg3		;[4] no more FCBs from disks to be had, but
	lda	fcbcnt		;[4]we have some in the buffer, havet we?
	ana	a
	jnz	mfnam1		;[4] yes, so all's ok.  Get an fcb and return,

mffix2:	xra	a
	sta	mfflg3		;[4] clear the new flag (=no more fcbs at all)
	sta	mfflg2		;[4] may as well do the others, as we're not comming again
	sta	mfflg1		;[4]
	stc			;set carry
	jmp	mffix1		;return with CARRY set

;       copy directory entry to FCB
;       called with A/ entry number in directory (0-3)
;                   directory block in DMA buffer (buff)

movfcb:	add	a
	add	a
	add	a
	add	a
	add	a		;* 32
	mov	c,a		; copy offset to bc
	mvi	b,0		; (high byte is zero)
	lxi	h,buff		; get start of disk buffer
	dad	b		; calculate start of directory entry
	lxi	d,fcb
	lxi	b,12
	call	mover
	ret

;       Data storage for MFNAME (multi-file access)
mfreq:	DS	12		;Requested name
mfflg1:	DB	0		;First time thru flag for MFNAME
mfflg2:	DB	0		;Down counter for MFNAME
mfflg3:	DB	0		;[4] Non zero if no more FCBs from disk,
				;[4] but we still have some in buffer
;
IF lasm
	LINK	CPSCMD
ENDIF;lasm

