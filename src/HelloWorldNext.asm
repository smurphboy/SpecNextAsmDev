			device		ZXSPECTRUMNEXT 
	
			org 		$8000			;Code Origin
Start			di
			ld		a,2
			out	 	254,a
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;	
	
	
                			    ;IPPPSLUN
 			nextreg 	$43,%00010000   	;Layer 2 to 1st palette	
		    	nextreg 	$40,0			;palette index 0
			ld 		b,4
			ld 		hl,MyPalette
paletteloop		ld 		a,(hl)			;get color (RRRGGGBB)
			inc 		hl
		    	nextreg 	$41,a           	;Send the colour 
    
			djnz 		paletteloop      	;Repeat for next color
	
			;nextreg 	$14,%00000001   	;Transparency color (RRRGGGBB)

		    	nextreg 	$16,0           	; Set X scroll to 0
			nextreg 	$17,0           	; Set Y scroll to 0
	
			nextreg 	$18,0			;X1
		    	nextreg 	$18,255			;X2
		    	nextreg 	$18,0			;Y1
    			nextreg 	$18,191         	;Y2

	;Enable Layer 2 (True color screen) and make it writable
	
				          ;BB--P-VW		-V= visible W=Write  B=bank
			ld 		a,%00000011
			ld 		bc,$123B
			out 		(c),a		
		
			nextreg 	$07,2			;CPU to 14mhz (0=3.5mjz 1=7mhz)
	

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;	
	
			;Test Pattern
			xor 		a
			ld 		de,$0000		;&0000-&3FFF is currently VRAM
			ld 		bc,$4000		;Fill &4000 bytes
FillColorsAgain		ld 		(de),a			;write a byte to VRAM
			inc 		de
			inc 		a
			dec 		c
			jr nz,		FillColorsAgain
			dec 		b
			jr nz,		FillColorsAgain

	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;	
	
	
			ld 		hl,Message		;Address of string
			call 		PrintString		;Show String to screen
			call 		NewLine
	
			ld 		hl,Message		;Address of string
			call 		PrintString		;Show String to screen
			call 		NewLine
	
			halt

	
Message			db 		'Hello World 543!',255

	
CursorX			db 0
CursorY			db 0

GetScreenPos		push 		af			;return memory pos in HL of screen co-ord B,C (X,Y)
			push 		bc
			ld 		l,b
			ld 		a,c
			and 		%00111111		;Offset in third
			ld 		h,a
		
			ld 		a,c
			and 		%11000000		;Bank in correct third for &0000-&3fff
		
				    	;BB--P-VW		-V= visible W=Write  B=bank
			or  		%00000011
		
			ld 		bc,$123B
			out 		(c),a			;BB---P-VW	- Page in and make visible
			pop 		bc
			pop 		af
			ret
		

NewLine			push 		hl
			ld 		hl,CursorX		;Inc X
			ld 		(hl),0
			inc 		hl
			inc 		(hl)			;Reset Y
			pop 		hl
			ret
	
PrintChar 		push 		af				;Print A to screen	
			push 		bc
			push 		de
			push 		hl
			push 		ix
			sub 		32			;First Char in our font is 32
	
			ld 		h,0			;8 bytes per character
			sla 		a
			rl 		h
			sla 		a
			rl 		h
			sla 		a
			rl 		h
			ld 		l,a

			ld 		de,BitmapFont		;Add Location of Bitmap font
			add 		hl,de
			ex 		de,hl
		
			ld 		a,(CursorX)		;8 bytes per char X
			rlca
			rlca
			rlca
			ld 		b,a
			ld 		a,(CursorY)		;8 Bytes per Char Y
			rlca
			rlca
			rlca
			ld 		c,a
			call 		GetScreenPos		;(B,C)->HL memory - also pages in ram to &0000-&3FFF

			ld 		ixl,8
PrintChar_NextLine	push 		hl
			ld 		b,8
			ld 		a,(de)			;Read in a byte from the font
			ld 		c,a
PrintChar_NextPixel	xor 		a
			rl 		c			;Pop of left most bit
			rl 		a
			ld 		(hl),a			;Write pixel to screen
			inc 		hl	
			djnz 		PrintChar_NextPixel 	;Next pixel
			pop 		hl
			inc 		h			;INC Y pos
			inc 		de
			dec 		ixl
			jr nz,		PrintChar_NextLine
		
			ld 		hl,CursorX		;Increase X
			inc 		(hl)
			ld 		a,(hl)			;At end of screen? (col 32)
			cp 		32
			call 		z,NewLine 		;Next line of our font
			pop 		ix
			pop 		hl
			pop 		de
			pop 		bc
			pop 		af
			ret	

PrintString		ld 		a,(hl)			;Print a '255' terminated string 
			cp 		255
			ret 		z
			inc 		hl
			call 		PrintChar
			jr 		PrintString


	   				;RRRGGGBB
MyPalette		db 		%00000001		;Dark blue
			db 		%11111100		;Yellow
			db 		%00011111		;Cyan
			db 		%11100000		;Red

BitmapFont
			ifdef 		BMP_UppercaseOnlyFont
				incbin "..\inc\Font64.FNT"	;Font bitmap, this is common to all systems
			else
				incbin "..\inc\Font96.FNT"	;Font bitmap, this is common to all systems
			endif
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
			SAVENEX 	OPEN "bin\HelloWorldNext.nex", Start
			SAVENEX 	AUTO
			SAVENEX 	CLOSE