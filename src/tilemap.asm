	device		zxspectrumnext
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;			Classic Spectrum Screen
	org		$8000
Start
	xor		a
	out 		($fe),a			;border=0
	
	
			    ;APPPSLUN
	nextreg		$43, %00110000		;Set Tilemap Palette
		
    	nextreg		$40,0           	;palette index 0 (TileMap)
	ld		b,16			;Entries
	ld		hl,MyPalette		;Source Definition
	call		DefinePalettes	
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;	
	
	;Tilemap (40x32)
	
			 ; ESAP--NU		E=Enable / S=Size (40x32 / 80x32) / A=Attributes (1=0ff)
	ld		a,%10100000		;TileMap on	 / P=Palettes (Pri/sec) / N=Tilenumber (256/512)
	nextreg		$6B,a			; U=tilemap over Ula
	     
	;offset
	nextreg 	$2F,0			;------XX - Xoffset H
	nextreg 	$30,0			;XXXXXXXX - Xoffset L
	nextreg 	$31,0			;YYYYYYYY - Yoffset 
	
	
	ld 		a,$40	
	nextreg 	$6E,a			;Tilemap Base Address (--HHHHHH)
	
	ld 		a,$50  	
	nextreg 	$6F,a			;Tile Pattern Base Address (--HHHHHH)
	
	
	ld		de,$5000		;Tile Patterns
	ld		hl,Tiles
	ld		bc,Tiles_End-Tiles
	ldir					;Copy tiles to Tile Pattern Ram
	
	
	ld		de,$4000		;TileMap 
	ld		hl,TileMap		;Source
	ld		bc,40*32		;Bytes
	ld		ixl,0			;Attribute (use for testing attribs)
	
SetTileLoop:
	;Tile Number
	ld		a,(hl)
	ld		(de),a			;NNNNNNNN - N=tile Number
	inc		hl
	inc		de			;Next Tile
	
	;;Tile Attribs
	ld		a,ixl
	xor		%00000001		;Transparent To ULA
	ld		ixl,a
	ld		(de),a			;PPPPXYRN - P=Palette / X=Xflip / Y=Yflip /
	inc		de			; R=Rotate / N=bit 9 tilenumber or ULA Transp

	dec 		bc			
	ld 		a,b
	or 		c
	jr		nz,SetTileLoop 		;Next Tile
	
	call 		DoPause
	
	; Tilemap to 256x192
	nextreg		$1B,16			;Window - X1
	nextreg 	$1B,143			;Window - X2
	nextreg 	$1B,32			;Window - Y1
	nextreg 	$1B,224			;Window - Y2
	
ScrollLoop:
	ei
	halt
	nextreg		$2F,0			;------XX - Xoffset H
	nextreg 	$30,a			;XXXXXXXX - Xoffset L
	nextreg 	$31,a			;YYYYYYYY - Yoffset 
	inc 		a

	jr 		ScrollLoop

DoPause:
	ld		b,100
PauseAgain:	
	ei
	halt
	djnz		PauseAgain		;Wait a while before we enable the ULA+ Palette
	ret	
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;		
OutiDE:
	outi					;Send a byte from HL to OUT (C)
	dec		de
	ld		a,d			;Repeat until DE=0
	or		e
	jr		nz,OutiDE
	ret
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;		

ShowSprite:		;A=HardSprite Num   BC = XY  H=hard sprite num

	;ld a,1
	push		bc
	ld		bc,$303B		;Sprite Status/Slot Select
	out		(c),a
	pop		bc
	
	ld		a,b
	out 		($57),a			;xpos 0 
	ld 		a,c
	out 		($57),a			;ypos 1
	 
	;	  	   PPPPXYRX 2
	ld 		a,%00000000
	out 		($57),a			;P P P P XM YM R X8/PR
						;P = 4-bit Palette Offset
						;XM = 1 to mirror the sprite image horizontally
						;YM = 1 to mirror the sprite image vertically
						;R = 1 to rotate the sprite image 90 degrees clockwise
						;X8 = Ninth bit of the sprite’s X coordinate
						;PR = 1 to indicate P is relative to the anchor’s palette offset (relative sprites only) 
			;  VENNNNNN 3
	ld 		a,%11000000
	or 		h
	out 		($57),a			;V E N5 N4 N3 N2 N1 N0
						;V = 1 to make the sprite visible
						;E = 1 to enable attribute byte 4
						;N = Sprite pattern to use 0-63 
						;If E=0, the sprite is fully described by sprite attributes 0-3. The sprite pattern is an 8-bit one identified by pattern N=0-63. The sprite is an anchor and cannot be made relative. The sprite is displayed as if sprite attribute 4 is zero. 
						;If E=1, the sprite is further described by sprite attribute 4. 

			;  HNTXXYYy 4
	ld 		a,%10000000
	out 		($57),a			;H N6 T X X Y Y Y8
						;H = 1 if the sprite pattern is 4-bit
						;N6 = 7th pattern bit if the sprite pattern is 4-bit
						;T = 0 if relative sprites are composite type else 1 for unified type
						;XX = Magnification in the X direction (00 = 1x, 01 = 2x, 10 = 4x, 11 = 8x)
						;YY = Magnification in the Y direction (00 = 1x, 01 = 2x, 10 = 4x, 11 = 8x)
						;Y8 = Ninth bit of the sprite’s Y coordinate 
						;{H,N6} must not equal {0,1} as this combination is used to indicate a relative sprite. 
	ret	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;		
	;8 bit palette definition

DefinePalettes:				
	ld 		a,(hl)			;get color (RRRGGGBB)
	inc 		hl
    	nextreg 	$41,a           	;Send the colour 
    	djnz 		DefinePalettes    	;Repeat for next color	
	ret
	
MySprite:
	;incbin "\ResALL\Sprites\Sprite_4bit.SPR"
	incbin 		"..\inc\Sprite_8bit.SPR"
MySprite_End:

MyPalette:		
 		        ;RRRGGGBB
    	db 		%00000000 ;0
    	db 		%10000010 ;1
    	db 		%00010000 ;2
    	db 		%11111111 ;3
	db 		%11100011 ;4
	db 		%11111100 ;5
	db 		%00010011 ;6
	db 		%10010000 ;7
	db 		%10010010 ;8
	db 		%11100000 ;9
	db 		%00011100 ;10
	db 		%11111100 ;11
	db 		%00000011 ;12
	db 		%11100011 ;13
	db 		%00011111 ;14
	db 		%11111111 ;15



Tiles:
	incbin 		"..\inc\TileSamples_4bpp.RAW"
Tiles_End:


TileMap:
	db 		1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1;1
	db 		0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0;2
	db 		0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0;3
	db 		0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0;4
	db 		0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0;5
	db 		0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0;6
	db 		0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0;7
	db 		0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0;8
	db 		0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0;9
	db 		0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0;10
	db 		0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0;11
	db 		0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,2,2,0,0,0,0;12
	db 		0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0;13
	db 		0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0;14
	db 		0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,2,2,0,0,0,0;15
	db 		0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0;16
	db 		0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,2,0,0;17
	db 		0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,2,0,0,0;18
	db 		0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,2,0,0,0,0;19
	db 		0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,2,0,0,0,0,0;20
	db 		0,2,0,0,0,0,0,0,0,0,0,2,0,0,2,0,0,2,0,0,0,0,0,0,0,2,0,0,2,0,0,0,0,2,0,0,0,0,0,0;21
	db 		0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,2,0,0,0,0,0,0,0;22
	db 		0,0,0,0,0,3,0,3,0,0,0,0,0,0,2,0,0,0,0,0,0,0,0,0,0,2,0,0,2,0,0,0,0,0,0,0,0,0,0,0;23
	db 		0,0,3,3,3,4,3,4,3,0,0,0,0,0,0,0,0,0,0,0,3,3,0,0,0,0,0,0,0,0,0,3,3,0,3,0,3,3,0,0;24
	db 		0,3,4,4,4,4,4,4,4,3,0,5,0,0,0,0,0,3,3,3,4,4,3,3,0,0,0,0,0,3,3,4,4,3,4,3,4,4,3,0;25
	db 		3,4,4,4,4,4,4,4,4,4,3,3,3,3,3,3,3,4,4,4,4,4,4,4,3,3,3,3,3,4,4,4,4,4,4,4,4,4,4,3;26
	db 		4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4;27
	db 		2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2;28
	db 		4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4;29
	db 		2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2;30
	db 		4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4;31
	db 		2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2;32
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	SAVENEX 	OPEN "bin/tilemap.nex", Start
	SAVENEX 	AUTO
	SAVENEX 	CLOSE
	;savesna "bin/tilemap.sna",START
                