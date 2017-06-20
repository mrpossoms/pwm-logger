'----------------------
' I2C Driver
'
	ORG 0
I2C_DRIVER
	MOV DIRA 

:LINE_STATE
	MOV R1, DIRA
	SHL R1, #30

	MOV R2, R1

:WAIT_START
	' Set both the SCL and SDA pins to inputs
	MOV DIRA, 0	


R1      LONG 0
R2      LONG 0
RET     LONG 0
SCL_PIN LONG $800000
SDA_PIN LONG $400000
'----------------------
FIT 496
