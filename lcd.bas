Dim control_port As Short
control_port = 0x80  'Reset high, everything else low
Put 2, control_port

Dim io_mode As Short
io_mode = 0b10000010  'Ports A and C (both halves) output, B input

Dim lcd_input As Boolean
lcd_input = True  'Ignore this
Call setlcdinput(False)

'Graphics mode
Call writelcd(0x02, 0)
Call writelcd(0x30, 0)  'Function set, 8-bit interface
Call writelcd(0x34, 0)  'Function set, extended instructions

Call clearlcd()
Call writelcd(0x36, 0)  'Function set, enable graphics

Call lcdsprite(0, 0)
Call lcdsprite(1, 1)

End                                               

Function spriteforchar(ch As Short) As Integer
	Dim addr As Integer
	addr = 0
	If ch = "_" Then
		addr = 4
	Endif
	spriteforchar = addr
End Function                                      

Proc lcdsprite(x As Integer, y As Integer)
	Dim row As Integer
	For row = 0 To 7
			Dim n As Integer
		n = y * 8 + row
		Call setlcdxy(x, n)
		Call writelcd(0xff, 1)
	Next row
End Proc                                          

Proc clearlcd()
	Dim y As Integer
	Dim x As Integer
	For y = 0 To 31
		Call setlcdxy(0, y)
		For x = 0 To 31
			Call writelcd(0x00, 1)
		Next x
	Next y
End Proc                                          

Proc setlcdxy(x As Integer, y As Integer)
	Dim cmd As Short
	If y < 32 Then
		cmd = y
		cmd = cmd Or 0x80
		Call writelcd(cmd, 0)
		cmd = x
		cmd = cmd Or 0x80
		Call writelcd(cmd, 0)
	Else
		cmd = y
		cmd = cmd - 32
		cmd = cmd Or 0x80
		Call writelcd(cmd, 0)
		cmd = x
		cmd = cmd Or 0x88
		Call writelcd(cmd, 0)
	Endif
End Proc                                          

Proc setlcdinput(input As Boolean)
	If input = lcd_input Then Return
	
	If input Then
		io_mode = io_mode Or 0b00010000
		control_port = control_port Or 0b00100000
	Else
		io_mode = io_mode And 0b11101111
		control_port = control_port And 0b11011111
	Endif

	lcd_input = input
	Put 3, io_mode
	Put 2, control_port
End Proc                                          

Proc writelcd(cmd As Short, rs As Short)
	Call waitnotbusy()
	Call setrs(rs)

	Put 0, cmd

	control_port = control_port Or 0b01000000
	Put 2, control_port
	control_port = control_port And 0b10111111
	Put 2, control_port
End Proc                                          

Proc setrs(rs As Short)
	If rs = 1 Then
		control_port = control_port Or 0b00010000
	Else
		control_port = control_port And 0b11101111
	Endif

	Put 2, control_port
End Proc                                          

Proc waitnotbusy()
	Call setlcdinput(True)
	Call setrs(0)
	Dim lcd_value As Short

	loop:
		control_port = control_port Or 0b01000000
		Put 2, control_port
		lcd_value = Get(0)
		control_port = control_port And 0b10111111
		lcd_value = lcd_value And 0x80
		If lcd_value <> 0 Then Goto loop

	Call setlcdinput(False)
End Proc                                          
