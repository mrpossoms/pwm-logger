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
	'OR A1, SCL_PIN
	'OR A1, SDA_PIN
	OR I2C_DIR, LED_MSK
	
	MOV DIRA, I2C_DIR
	MOV OUTA, I2C_OUT

:JUNK
	CALL #WAIT_SC
	ANDN I2C_OUT, LED_MSK
	MOV OUTA, I2C_OUT
	CALL #WAIT_ADDR_FRAME

	ANDN I2C_OUT, LED0
	ANDN I2C_OUT, LED1
	MOV OUTA, I2C_OUT 
	JMP #:JUNK

'---------------
NEXT_CLOCK
	MOV I2C_STOPPING, 0
	
	WAITPEQ ZERO, SCL_PIN      ' Wait for the clock line to go low
	MOV I2C_TIMEOUT, CNT

	' LED0 off at low
	ANDN I2C_OUT, LED0
	MOV OUTA, I2C_OUT

	WAITPEQ SCL_PIN, SCL_PIN ' Next wait for it to go high
	SUB I2C_TIMEOUT, CNT
	ABS I2C_TIMEOUT, I2C_TIMEOUT
	SHL I2C_TIMEOUT, #1 ' double the timeout

	' LED0 on at hi
	OR I2C_OUT, LED0
	MOV OUTA, I2C_OUT

	' SDA_BIT becomes a 1 or a 0 depending on the pin state
	MOV SDA_BIT, INA
	AND SDA_BIT, SDA_PIN
	CMP SDA_BIT, ZERO WZ, WR

	' LED1 on at SDA hi
	IF_Z ANDN I2C_OUT, LED1
	' IF_Z MOV SDA_BIT, #0
	IF_NZ OR I2C_OUT, LED1
	' IF_NZ MOV SDA_BIT, #1
	MOV OUTA, I2C_OUT

	' Wait for SCL to go low again, but timeout if it doesnt
	' in which case a stop condition has been issued
:CHECK_STOP
	MOV I2C_TMP, INA
	AND I2C_TMP, I2C_MSK
	
	' Writes Z or C bits if clock goes low
	CMP I2C_TMP, SDA_PIN  WZ, WC
	IF_C_OR_Z JMP #:NEXT_CLOCK_DONE
	
	DJNZ I2C_TIMEOUT, #:CHECK_STOP
	' Timeout occured, is SDA high?
	AND I2C_TMP, SDA_PIN WZ
	IF_NZ MOV I2C_STOPPING, #1
	
:NEXT_CLOCK_DONE
NEXT_CLOCK_RET RET

'---------------
WAIT_SCL_LO
	WAITPEQ ZERO, SCL_PIN
WAIT_SCL_LO_RET RET

'-----------------
WAIT_SC
	' Set both the SCL and SDA pins to inputs
	ANDN I2C_DIR, I2C_MSK 
	MOV DIRA, I2C_DIR

	' Wait for SDA to go HI, with SCL HI
	WAITPEQ SCL_HI_SDA_HI, I2C_MSK

	' Wait for SDA to go low, and SCL to stay HI
	WAITPEQ SCL_HI_SDA_LO, I2C_MSK
WAIT_SC_RET RET	

'---------------
RECEIVE_BYTE
	MOV A1, #8
	MOV I2C_BYTE, #0
:RX_NEXT_BIT
	CALL #NEXT_CLOCK
	ADD I2C_BYTE, SDA_BIT
	SHL I2C_BYTE, #1
	DJNZ A1, #:RX_NEXT_BIT
RECEIVE_BYTE_RET RET

'---------------
WAIT_ADDR_FRAME
	' The 8th bit will being set will indicate that
	' all 7 addr bits have been read
	MOV ADDR_FRAME, #$02

	' Set both the SCL and SDA pins to inputs
	ANDN I2C_DIR, I2C_MSK 
	MOV DIRA, I2C_DIR
	
	' Turn LED1 on when address frame reading begins
	'OR I2C_OUT, LED1
	'MOV OUTA, I2C_OUT

:WAIT_ADDR_FRAME_CONT
	CALL #NEXT_CLOCK

	' If SDA is high, set this bit as a 1
	ADD ADDR_FRAME, SDA_BIT
	SHL ADDR_FRAME, #1

	' If the 9th bit isn't a 1 yet, then we are
	' not done reading
	MOV A1, ADDR_FRAME
	AND A1, #$100
	TJZ A1, #:WAIT_ADDR_FRAME_CONT

	' The master has finished addressing the slaves.
	' Were we the one addressed?
	MOV A1, ADDR_FRAME
	AND A1, #$FE
	CMP A1, MY_ADDR WZ
	IF_NZ MOV RET_VAL, #0
	IF_NZ JMP #:WAIT_ADDR_FRAME_QUIT

	' We were addressed
	CALL #ACK	

	OR I2C_OUT, LED2
	MOV OUTA, I2C_OUT

	' Read the RW bit
	MOV IS_READ_MODE, SDA_BIT

	MOV RET_VAL, #1

:WAIT_ADDR_FRAME_QUIT
WAIT_ADDR_FRAME_RET RET

'---------------
ACK
	' Set SDA to output
	OR I2C_DIR, SDA_PIN
	MOV DIRA, I2C_DIR

	WAITPEQ ZERO, SCL_PIN

	' Drive SDA low
	ANDN I2C_OUT, SDA_PIN
	MOV OUTA, I2C_OUT

	WAITPEQ SCL_PIN, SCL_PIN
	WAITPEQ ZERO, SCL_PIN
	WAITPEQ SCL_PIN, SCL_PIN
	WAITPEQ ZERO, SCL_PIN

	' Set SDA back to input	
	ANDN I2C_DIR, SDA_PIN
	MOV DIRA, I2C_DIR
ACK_RET RET


A1            LONG 0
RET_VAL       LONG 0
SDA_BIT       LONG 0
SCL_BIT       LONG 0
I2C_BYTE      LONG 0
ZERO          LONG 0

I2C_DIR       LONG 0
I2C_OUT       LONG 0
I2C_TIMEOUT   LONG 0
I2C_STOPPING  LONG 0
I2C_TMP       LONG 0

MY_ADDR       LONG $D2  ' 0x69
ADDR_FRAME    LONG 0 ' Dev addr mentioned by the master
IS_READ_MODE  LONG 0
SCL_PIN       LONG $020000
SDA_PIN       LONG $040000
LED0          LONG $8000
LED1          LONG $4000
LED2          LONG $2000
LED_MSK       LONG $E000
SCL_LO_SDA_LO LONG 0
SCL_LO_SDA_HI LONG 0
SCL_HI_SDA_LO LONG 0
SCL_HI_SDA_HI LONG 0
I2C_MSK       LONG $C00000
'----------------------
FIT 496
