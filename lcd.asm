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
.page_shown:   equ .pixel_buffer + (128*8) ; What the current vertical scroll address is
;.lcdstack:     equ .pixel_buffer+(128*8) ; pointer to stack for scratch stuff

;.pushbyte: macro
;	ld hl,(.lcdstack)
;	inc hl
;	ld (hl),a
;	ld (.lcdstack),hl
;	endm

	org 0000

	call lcd_reset
	call lcd_clear
	call lcd_redraw

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

lcd_redraw:
	push af
	push bc
	push hl
	ld c,0 ; Row we're on
	ld hl,(.pixel_buffer) ; Buffer byte we're on
.drawrow:
	ld b,0
	call .setxy
	ld b,16
.send_byte:
	ld a,(hl)
	inc hl
	call .writedata
	djnz .send_byte
	inc c
	bit 6,c
	jr z,.drawrow
	pop hl
	pop bc
	pop af
	ret

lcd_clear:
	push af
	push bc
	push hl
	ld c,0 ; Row we're on
	ld hl,(.pixel_buffer) ; Buffer byte we're on
	ld a,0
.clearrow:
	ld b,16
.draw_empty:
	ld (hl),a
	inc hl
	djnz .draw_empty
	inc c
	bit 6,c
	jr z,.clearrow
	pop hl
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

	sub a ; We're showing the page starting at line 0
	ld (.page_shown),a

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