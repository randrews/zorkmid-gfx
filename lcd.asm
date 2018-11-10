.ctrl_reset:  equ 10000000b ; clear for reset
.ctrl_e:      equ 01000000b ; set, then falling edge, to latch
.ctrl_rw:     equ 00100000b ; set for input
.ctrl_rs:     equ 00010000b ; set for data
.led2:        equ 00001000b
.led1:        equ 00000100b
.io_write:    equ 10000010b
.io_read:     equ 10010010b
.addr_data:   equ 0
.addr_btns:   equ 1
.addr_ctrl:   equ 2
.addr_dir:    equ 3

.ram_base:     equ 0x8000
.pixel_buffer: equ .ram_base ; Enough bits for 1 bpp for the whole screen
.scratch:      equ .pixel_buffer+(128*8) ; 32 bytes of scratch stuff

	org 0000

	call lcd_reset
	call lcd_clear

	halt

include "tiles.asm"

; x in b, y in c
.setxy:
	push af
	ld a,c
	cp 32
	jr c,.tophalf
	sub 32
	or 0x80
	call .writecmd
	ld a,b
	or 0x88
	call .writecmd
	jr .setxy_done
.tophalf:
	or 0x80
	call .writecmd
	ld a,b
	or 0x80
	call .writecmd
.setxy_done:
	pop af
	ret

; Sets a tile on the grid: tile addr in hl, x in b, y in c
set_tile:
	ret

lcd_clear:
	push af
	push bc
	ld c,64 ; Row we're on
.clearrow:
	ld b,0
	call .setxy
	ld b,16
.send_empty:
	ld a,0x55
	call .writedata
	djnz .send_empty
	dec c
	bit 7,c
	jr z,.clearrow
	pop bc
	pop af
	ret

lcd_reset:
	push af
	call .setoutput

	ld a,0
	out (.addr_ctrl),a
	ld a,.ctrl_reset
	out (.addr_ctrl),a

	ld a,0x02
	call .writecmd
	ld a,0x30 ; Function set, 8-bit interface
	call .writecmd
	ld a,0x34 ; Function set, extended instructions
	call .writecmd
	ld a,0x36 ; Enable graphics
	call .writecmd

	pop af
	ret

.setinput:
	push af
	ld a,.io_read
	out (.addr_dir),a
	ld a, .ctrl_reset | .ctrl_rw
	out (.addr_ctrl),a
	pop af
	ret

.setoutput:
	push af
	ld a,.io_write
	out (.addr_dir),a
	ld a,.ctrl_reset
	out (.addr_ctrl),a
	pop af
	ret

; Return the LCD status byte in register A
.readstatus:
	push bc
	ld a,.ctrl_reset | .ctrl_rw
	out (.addr_ctrl),a
	xor .ctrl_e
	out (.addr_ctrl),a
	in a,(.addr_data)
	ld b,a
	ld a,.ctrl_reset | .ctrl_rw
	out (.addr_ctrl),a
	ld a,b
	pop bc
	ret

; Loop until the LCD isn't busy
.waitnotbusy:
	push af
	call .setinput
.waitloop:
	call .readstatus
	bit 7,a
	jr nz,.waitloop
	pop af
	ret

; Write the byte in register A to the LCD as a command
.writecmd:
	push af
	call .waitnotbusy
	call .setoutput
	out (.addr_data),a
	ld a,.ctrl_reset
	out (.addr_ctrl),a
	xor .ctrl_e
	out (.addr_ctrl),a
	xor .ctrl_e
	out (.addr_ctrl),a
	pop af
	ret

.writedata:
	push af
	call .waitnotbusy
	call .setoutput
	out (.addr_data),a
	ld a, .ctrl_reset | .ctrl_rs
	out (.addr_ctrl),a
	xor .ctrl_e
	out (.addr_ctrl),a
	xor .ctrl_e
	out (.addr_ctrl),a
	pop af
	ret