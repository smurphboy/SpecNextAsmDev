; hello-world.z80
CHAN_OPEN       equ 5633
PRINT           equ 8252

                org 32512

                ld      a,2
                call    CHAN_OPEN
                ld      de, text
                ld      bc, textend-text
                jp      PRINT

text            defb    'Hello, World!'

                defb    13

textend         equ     $
