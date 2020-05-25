; hello-world.z80
                DEVICE ZXSPECTRUM48

CHAN_OPEN       equ     5633
PRINT           equ     8252

                org     $8000

START           ld      a,2
                call    CHAN_OPEN
                ld      de, text
                ld      bc, textend-text
                jp      PRINT
                ret

text            defb    'Hello, World!'

                defb    13

textend         equ     $

                ;SAVENEX OPEN "bin/Helloworld.nex", START
                savesna "bin/Helloworld.sna",START
                