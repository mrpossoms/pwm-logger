'----------------------
' I2C Driver
'
	ORG 0
I2C_DRIVER
	MOV DIRA, 0
	OR SCL_LO_SDA_HI, SDA_PIN
	OR SCL_HI_SDA_LO, SCL_PIN
	MOV SCL_HI_SDA_HI, I2C_MSK
	MOV WAIT_MSK, I2C_MSK

'---------------
WAIT_SCL_LO
	MOV R1, INA
	AND R1, SCL_PIN
	TJNZ R1, #WAIT_SCL_LO
WAIT_SCL_LO_RET RET

'---------------
WAIT_FOR_TARGET
	ADD WAIT_T_OUT, CNT
:WAIT_FOR_IN_CONT
	' Compare the expected timout CNT with current
	CMP WAIT_T_OUT, CNT WC

	' If the timeout expired, return failure
	IF_C MOV RET_VAL, #0
	IF_C RET

	' Grab the current pin state, check for a match
	MOV WAIT_L_IN, INA
	MOV WAIT_L_SDA, WAIT_L_IN
	AND WAIT_L_SDA, SDA_PIN
	AND WAIT_L_IN, WAIT_MSK	
	CMP WAIT_L_IN, WAIT_TARGET         ' Compare INA and target, WAIT_L_IN is set to 0 when they are equal
	TJNZ WAIT_L_IN, #:WAIT_FOR_IN_CONT ' Keep waiting

	' They are equal!
	MOV RET_VAL, #1
WAIT_FOR_TARGET_RET RET

'----------------
NEXT_BIT
	' Wait for the clock to go low
	MOV WAIT_MSK, SCL_PIN
	MOV WAIT_T_OUT, SC_CYLS
	MOV WAIT_TARGET, #0
	CALL #WAIT_FOR_TARGET
	MOV R1, RET_VAL

	' Now wait for it to go high!
	MOV WAIT_T_OUT, SC_CYLS
	MOV WAIT_TARGET, SCL_PIN
	ADD R1, RET_VAL

	' If R1 is not 2, an error occured	
	SUB R1, #2
	TJZ R1, #:NEXT_BIT_OK
	MOV RET_VAL, #0
	RET

:NEXT_BIT_OK
	MOV RET_VAL, #1 ' All is well
NEXT_BIT_RET RET

'-----------------
WAIT_SC
	' Set both the SCL and SDA pins to inputs
	MOV DIRA, #0
	
	' Watch both SDA and SCL
	MOV WAIT_MSK, I2C_MSK

	' Wait for SCL to go low, with SDA_HIGH
	MOV WAIT_TARGET, SCL_LO_SDA_HI
	MOV WAIT_T_OUT, SC_CYLS
	CALL #WAIT_FOR_TARGET

	' Make sure we detected the condition or return failure
	CMP RET_VAL, #1 WZ
	IF_NZ MOV RET_VAL, #0
	IF_NZ RET	

	' Wait for SCL to stay low, and SDA to go low
	MOV WAIT_TARGET, #0
	MOV WAIT_T_OUT, SC_CYLS
	CALL #WAIT_FOR_TARGET

	' Make sure we detected the condition or return failure
	CMP RET_VAL, #1 WZ 
	IF_NZ MOV RET_VAL, #0
	IF_NZ RET	

WAIT_ADDR_FRAME
	' The 8th bit will being set will indicate that
	' all 7 addr bits have been read
	MOV ADDR_FRAME, #$02

	' Set both the SCL and SDA pins to inputs
	MOV DIRA, #0

:WAIT_ADDR_FRAME_CONT
	CALL #NEXT_BIT
	CMP RET_VAL, SDA_PIN WZ	

	' If SDA is high, set this bit as a 1
	IF_Z ADD ADDR_FRAME, #1
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
	CALL #NEXT_BIT
	CMP RET_VAL, SDA_PIN WZ
	IF_Z MOV IS_READ_MODE, #1
	IF_NZ MOV IS_READ_MODE, #0

	MOV RET_VAL, #0
	RET

ACK
	' Set SDA to output
	MOV DIRA, SDA_PIN

	CALL #WAIT_SCL_LO

	' Drive SDA low
	MOV OUTA, 0		

'R1            LONG 0
'R2            LONG 0
RET_VAL       LONG 0
WAIT_START    LONG 0
WAIT_MSK      LONG 0
WAIT_TARGET   LONG 0
WAIT_T_OUT    LONG 0
WAIT_L_IN     LONG 0
WAIT_L_SDA    LONG 0  

MY_ADDR       LONG $69
ADDR_FRAME    LONG 0 ' Dev addr mentioned by the master
IS_READ_MODE  LONG 0
SC_CYLS       LONG 1000 'TODO: figure out what this should be
SDA_OLD       LONG 0
SCL_PIN       LONG $800000
SDA_PIN       LONG $400000
SCL_LO_SDA_HI LONG 0
SCL_HI_SDA_LO LONG 0
SCL_HI_SDA_HI LONG 0
I2C_MSK     LONG $C00000
'----------------------
FIT 496
