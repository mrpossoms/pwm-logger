'----------------------
' I2C Driver
'
	ORG 0
I2C_DRIVER
	MOV DIRA, ZERO
	MOV I2C_MSK, SDA_PIN
	OR I2C_MSK, SCL_PIN
	OR SCL_LO_SDA_HI, SDA_PIN
	OR SCL_HI_SDA_LO, SCL_PIN
	MOV SCL_HI_SDA_HI, I2C_MSK

'---------------
NEXT_CLOCK
	WAITPEQ ZERO, SCL_PIN      ' Wait for the clock line to go low
	WAITPEQ SCL_PIN, SCL_PIN ' Next wait for it to go high

	' SDA_BIT becomes a 1 or a 0 depending on the pin state
	MOV SDA_BIT, INA
	CMP SDA_BIT, ZERO
NEXT_CLOCK_RET RET

'---------------
WAIT_SCL_LO
	MOV R1, INA
	AND R1, SCL_PIN
	TJNZ R1, #WAIT_SCL_LO
WAIT_SCL_LO_RET RET

'-----------------
WAIT_SC
	' Set both the SCL and SDA pins to inputs
	MOV DIRA, ZERO

	' Wait for SCL to go low, with SDA_HIGH
	WAITPEQ SCL_LO_SDA_HI, I2C_MSK

	' Wait for SCL to stay low, and SDA to go low
	WAITPEQ SCL_LO_SDA_LO, I2C_MSK
WAIT_SC_RET RET	

'---------------
RECEIVE_BYTE
	MOV R1, #8
	MOV I2C_BYTE, #0
:RX_NEXT_BIT
	CALL #NEXT_CLOCK
	ADD I2C_BYTE, SDA_BIT
	SHL I2C_BYTE, #1
	DJNZ R1, #:RX_NEXT_BIT
RECEIVE_BYTE_RET RET

'---------------
WAIT_ADDR_FRAME
	' The 8th bit will being set will indicate that
	' all 7 addr bits have been read
	MOV ADDR_FRAME, #$02

	' Set both the SCL and SDA pins to inputs
	MOV DIRA, #0

:WAIT_ADDR_FRAME_CONT
	CALL #NEXT_CLOCK

	' If SDA is high, set this bit as a 1
	ADD ADDR_FRAME, SDA_BIT
	SHR ADDR_FRAME, #1

	' If the 8th bit isn't a 1 yet, then we are
	' not done reading
	MOV R1, ADDR_FRAME
	AND R1, #$80
	TJZ R1, #:WAIT_ADDR_FRAME_CONT

	' The master has finished addressing the slaves.
	' Were we the one addressed?
	AND R1, #$7F
	CMP R1, MY_ADDR WZ
	IF_NZ MOV RET_VAL, #0
	IF_NZ RET

	' Read the RW bit
	CALL #NEXT_CLOCK
	CMP SDA_BIT, #1 WZ
	IF_Z MOV IS_READ_MODE, #1
	IF_NZ MOV IS_READ_MODE, #0

	MOV RET_VAL, #1
	RET

'---------------
ACK
	' Set SDA to output
	MOV DIRA, SDA_PIN

	CALL #WAIT_SCL_LO

	' Drive SDA low
	MOV OUTA, 0		

'R1            LONG 0
'R2            LONG 0
RET_VAL       LONG 0
SDA_BIT       LONG 0
I2C_BYTE      LONG 0
ZERO          LONG 0

MY_ADDR       LONG $69
ADDR_FRAME    LONG 0 ' Dev addr mentioned by the master
IS_READ_MODE  LONG 0
SCL_PIN       LONG $800000
SDA_PIN       LONG $400000
SCL_LO_SDA_LO LONG 0
SCL_LO_SDA_HI LONG 0
SCL_HI_SDA_LO LONG 0
SCL_HI_SDA_HI LONG 0
I2C_MSK       LONG $C00000
'----------------------
FIT 496
