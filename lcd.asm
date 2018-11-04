.ctrl_reset: equ 10000000b ; clear for reset
.ctrl_e:     equ 01000000b ; set, then falling edge, to latch
.ctrl_rw:    equ 00100000b ; set for input
.ctrl_rs:    equ 00010000b ; set for data
.io_write:   equ 10000010b
.io_read:    equ 10010010b
.addr_data:  equ 0
.addr_ctrl:  equ 2
.addr_dir:   equ 3

	halt

lcd_reset:
	push af
	; Set the reset pin
	ld	a,.ctrl_reset
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
	ld a,(.ctrl_reset | .ctrl_rw)
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
	ld a,(.ctrl_reset | .ctrl_rs | .ctrl_e | .ctrl_rw)
	out (.addr_ctrl),a
	xor .ctrl_e
	out (.addr_ctrl),a
	in a,(.addr_data)
	ret

; Loop until the LCD isn't busy
.waitnotbusy:
	push af
	call .setinput
.waitloop:
	call .readstatus
	bit 7,b
	jr nz,.waitloop
	pop af
	ret

; Write the byte in register A to the LCD as a command
.writecmd:
	push af
	call .waitnotbusy
	out (.addr_data),a
	call .setoutput
	ld a,(.ctrl_reset | .ctrl_e)
	out (.addr_ctrl),a
	xor .ctrl_e
	out (.addr_ctrl),a
	pop af
	ret

.writedata:
	push af
	call .waitnotbusy
	out (.addr_data),a
	call .setoutput
	ld a,(.ctrl_reset | .ctrl_e | .ctrl_rs)
	out (.addr_ctrl),a
	xor .ctrl_e
	out (.addr_ctrl),a
	pop af
	ret