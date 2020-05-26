	DEVICE			ZXSPECTRUMNEXT
; hello-world.z80
	org 			$8000			;Code Origin
START	
	ld 			hl,Message		;Address of string
	call 			PrintString		;Show String to screen
	halt
	ret
	
NewLine:
	ld 			a,13			;Carriage return only - Spectrum doesn't like CHR(10)
	jr 			PrintChar
	
	
PrintChar:
	push 			hl
	push 			bc
	push 			de			
	push 			af
	ld 			a,2			;Select Stream 2 = topscreen
	call 			$1601			;CHAN_OPEN
	pop 			af
	push 			af
	rst 			16			;call &0010	;PRINT_A_1
	pop 			af
	pop 			de
	pop 			bc			
	pop 			hl
	ret	

PrintString:
	ld 			a,(hl)			;Print a '255' terminated string 
	cp 			255
	ret 			z
	inc 			hl
	call 			PrintChar
	jr 			PrintString

Message:
	db 			'Hello World 323!',255

        SAVENEX OPEN "bin/Helloworld.nex", START
	SAVENEX AUTO
	SAVENEX CLOSE
        ;savesna "bin/Helloworld.sna",START
                