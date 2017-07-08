'----------------------
' I2C Driver
'
' This file implements a simple I2C slave driver. The device can be
' addressed by a master with a 7bit address MY_ADDR. Once addressed,
' writing a single byte will select the control register. A second
' consecutive byte will write that value into the selected register. 
' The control registers available are... 
'
' bit reg  description
'______________________________
' R  | 0 | Device configuration
' RW | 1 | Servo channel 1
' RW | 2 | Servo channel 2
' ...
' R2 | N | Servo channel N
'
' Servo channel N - Each servo has a corresponding register that holds
'                   a 1 byte value that corresponds to some pulse width
'                   for driving servos. These registers can be read from
'                   when the device is in echo mode, or written to when it
'                   is not. When writing to or reading from a servo channel
'                   the SEL_REG is automatically incremented so that each
'                   following channel need not be addressed individually.
'
' Device configuration - This register controls the device mode.
'                        A 0 written into this register will take it out
'                        of echo mode and cause the PWM cogs to generate
'                        the pulse width that was last written to or decoded from
'                        A 1 puts the device into echo mode in which case the
'                        pulse width measured on the input pins are decoded
'                        as a byte and stored in each channel. The signal is also
'                        passed through to the respective output pins.

	ORG 0
I2C_DRIVER
	MOV           I2C_MSK, SDA_PIN
	OR            I2C_MSK, SCL_PIN

	OR            I2C_DIR, LED_MSK
	ANDN          I2C_OUT, LED_MSK
	
	MOV           DIRA, I2C_DIR
	MOV           OUTA, I2C_OUT

:JUNK
	' Wait for start condition
	CALL          #NEXT_CONDITION
	CMP           I2C_STATE, #1 WZ
	IF_NZ JMP     #:JUNK

	' Read the address frame, if we
	' were not the ones addressed then start over
	CALL          #WAIT_ADDR_FRAME
	CMP           RET_VAL, #1 WZ
	IF_NZ JMP     #:JUNK

	' We were addressed	
	CALL          #ACK

	' Does the master want to read or write?
	TJNZ          IS_READ_MODE, #:MASTER_READ

:MASTER_WRITE  ' Master is sending data
	MOV           FIRST, #0
:MASTER_WRITE_LOOP
	CALL          #READ_BYTE

	' Was this not a data byte? IE START or STOP?
	AND           I2C_STATE, #3 WZ, NR
	IF_NZ JMP     #:JUNK

	' If it's a normal byte, send the ack
	CALL          #ACK

	' Let the first byte select the register
	CMP           FIRST, #0 WZ
	IF_Z MOV      FIRST, #1
	IF_Z MOV      SEL_REG, I2C_BYTE ' If no, select the register
	IF_NZ JMP     #:WRITE_BUF ' If yes, write to where the reg indicates
	JMP           #:MASTER_WRITE_LOOP

:WRITE_BUF
	CMP                 SEL_REG, #0 WZ
	IF_Z WRLONG         I2C_BYTE, I2C_SHOULD_ECHO
	CMP                 SEL_REG, #0 WC, WZ
	IF_NC_AND_NZ SHL    I2C_BYTE, #10
	IF_NC_AND_NZ MOV    I2C_TMP, SEL_REG
	IF_NC_AND_NZ SUB    I2C_TMP, #1
	IF_NC_AND_NZ SHL    I2C_TMP, #2
	IF_NC_AND_NZ ADD    I2C_TMP, I2C_SERVO_0
	IF_NC_AND_NZ WRLONG I2C_BYTE, I2C_TMP
	ADD                 SEL_REG, #1
	JMP                 #:MASTER_WRITE_LOOP
:MASTER_WRITE_DONE	

:MASTER_READ   ' Master is receiving data 
	MOV           COUNT, #0
:MASTER_READ_LOOP
	MOV           I2C_TMP, COUNT
	SHL           I2C_TMP, #2
	ADD           I2C_TMP, I2C_SERVO_0
	RDLONG        I2C_BYTE, I2C_TMP
	SHR           I2C_BYTE, #10

	CALL          #WRITE_BYTE

	' Release the SDA, Let the master ACK
	CALL          #MACK	

	ADD           COUNT, #1

	' MACK will set RET_VAL to 0 if a NACK was
	' received from the master
	TJNZ          RET_VAL, #:MASTER_READ_LOOP
:MASTER_READ_DONE

	IF_Z MOV      I2C_OUT, LED0
	MOV           OUTA, I2C_OUT

	JMP           #:JUNK


'---------------
' NEXT_CONDITION - This routine waits for the SCL bus to transition to a
'                  new state. This detects START, STOP or data bit conditions.
'                  The state change detected is written to I2C_STATE. In the
'                  event that a data bit is detected, you can retrieve it by
'                  accessing the SDA_BIT register
NEXT_CONDITION

	MOV           I2C_STATE, #0
	
	ANDN          I2C_OUT, LED_MSK

	' Set both the SCL and SDA pins to inputs
	ANDN          I2C_DIR, I2C_MSK 
	MOV           DIRA, I2C_DIR

	' Wait for high clock
	WAITPEQ       SCL_PIN, SCL_PIN

	' Get the starting line state
	MOV           I2C_LINE_ST, INA
	AND           I2C_LINE_ST, I2C_MSK

	' Wait peak duration
:COND_WAIT_PEAK
	' Get the current line state
	MOV           I2C_TMP, INA
	AND           I2C_TMP, I2C_MSK
	CMP           I2C_TMP, I2C_LINE_ST WZ
	IF_Z JMP      #:COND_WAIT_PEAK   ' No change, keep waiting

	' Get the SDA bit value
	MOV           SDA_BIT, I2C_TMP
	AND           SDA_BIT, SDA_PIN

	' Isolate the clock
	MOV           SCL_BIT, I2C_TMP
	AND           SCL_BIT, SCL_PIN
	
	' Did the clock drop lo? Exit loop
	CMP           SCL_BIT, SCL_PIN WZ
	' LED0 off for lo clock
	IF_NZ OR      I2C_OUT, LED1
	IF_NZ MOV     OUTA, I2C_OUT
	IF_NZ JMP     #:COND_EXIT

	' An SDA edge must have occured
	AND           SDA_BIT, SDA_PIN WZ
	IF_Z MOV      I2C_STATE, #1     ' hi->lo: START occured
	IF_Z WAITPEQ  ZERO, SCL_PIN ' After the START, wait for a low clock
	IF_Z OR       I2C_OUT, LED0
	IF_NZ MOV     I2C_STATE, #2    ' lo->hi: STOP occured
	IF_NZ OR      I2C_OUT, LED2

:COND_EXIT
	' convert SDA_BIT to its LSb
	AND       SDA_BIT, SDA_PIN WZ
	IF_NZ MOV SDA_BIT, #1
	IF_Z MOV  SDA_BIT, #0

	MOV       OUTA, I2C_OUT
	
NEXT_CONDITION_RET RET


'---------------
' READ_BYTE - This routine reads a byte from the master into I2C_BYTE one
'             bit at a time at the clock rate generated by the master. No
'             ACK is sent after reception.
READ_BYTE
	MOV           COUNT, #8
	MOV           I2C_BYTE, #0
:RX_NEXT_BIT
	CALL          #NEXT_CONDITION

	' Did we detect a stop or a repeated start this cycle?
	' If so, we should quit reading this byte
	AND           I2C_STATE, #3 WZ, NR
	IF_NZ MOV     I2C_BYTE, #0
	IF_NZ JMP     #:READ_BYTE_DONE

	SHL           I2C_BYTE, #1
	ADD           I2C_BYTE, SDA_BIT
	DJNZ          COUNT, #:RX_NEXT_BIT

:READ_BYTE_DONE
READ_BYTE_RET RET


'---------------
' WRITE_BYTE - This routine transmits the byte currently held in I2C_BYTE
'              one bit at a time at the clock rate generated by the master.
'              This routine is destructive to the data in I2C_BYTE. 
WRITE_BYTE
	MOV           COUNT, #8
	OR I2C_DIR, SDA_PIN ' Set SDA to output
	MOV DIRA, I2C_DIR
:TX_NEXT_BIT
	WAITPEQ ZERO, SCL_PIN
	
	' Drive the SDA line based on the value
	' of the MSb
	AND I2C_BYTE, #$80 WZ, NR
	IF_Z ANDN I2C_OUT, SDA_PIN
	IF_NZ OR I2C_OUT, SDA_PIN
	MOV OUTA, I2C_OUT

	' Wait for hi, then lo
	WAITPEQ SCL_PIN, SCL_PIN
	WAITPEQ ZERO, SCL_PIN

	' Shift to the next bit
	SHL I2C_BYTE, #1

	DJNZ          COUNT, #:TX_NEXT_BIT

:WRITE_BYTE_DONE
WRITE_BYTE_RET RET


'---------------
' WAIT_ADDR_FRAME - This routine reads a byte from the master who currently
'                   has control of the bus. If the 7 bit address transmitted
'                   matches our slave address then RET_VAL is set to 1,
'                   otherwise 0. The R/W bit is also extracted from the byte
'                   and IS_READ_MODE is set accordingly
WAIT_ADDR_FRAME
	CALL      #READ_BYTE
	MOV       RET_VAL, #0

	' The master has finished addressing the slaves.
	' Were we the one addressed?
	MOV       ADDR_FRAME, I2C_BYTE
	AND       ADDR_FRAME, #$FE
	CMP       ADDR_FRAME, MY_ADDR WZ
	IF_NZ JMP #:WAIT_ADDR_FRAME_QUIT

	' Read the RW bit
	MOV       IS_READ_MODE, SDA_BIT
	MOV       RET_VAL, #1

:WAIT_ADDR_FRAME_QUIT
WAIT_ADDR_FRAME_RET RET


'---------------
' MACK - This routine waits for the master to acknowledge the byte
'        that we just finished sending. A MACK condition occurs when
'        SCL goes high, and the master holds the SDA line low for the
'        pulse duration. If a MACK is detected RET_VAL is set to 1
'        otherwise RET_VAL is set to 0.
MACK
	' Set the SDA pin to input
	ANDN I2C_DIR, SDA_PIN
	MOV DIRA, I2C_DIR

	' Wait for a high clock
	WAITPEQ SCL_PIN, SCL_PIN

	' Get the SDA bit
	MOV I2C_LINE_ST, INA
	AND I2C_LINE_ST, SDA_PIN WZ, NR

	' Wait for the clock to go low again
	WAITPEQ ZERO, SCL_PIN

	IF_Z MOV RET_VAL, #1
	IF_NZ MOV RET_VAL, #0

MACK_RET RET


'---------------
' ACK - This routine will sends an I2C slave ACK to the master.
'       It  waits for the master to drive the SCL line low, at
'	which point we then drive the SDA line low. Finally, 
'       the next high SCL pulse is waited for. At which point
'       we release the SDA line and return.
ACK
	' Set SDA to output
	OR        I2C_DIR, SDA_PIN
	MOV       DIRA, I2C_DIR

	OR        I2C_OUT, LED1
	MOV       OUTA, I2C_OUT

	' Wait for the clock to go lo
	WAITPEQ   ZERO, SCL_PIN

	OR        I2C_OUT, LED1
	MOV       OUTA, I2C_OUT

	' Drive SDA low
	ANDN      I2C_OUT, SDA_PIN
	MOV       OUTA, I2C_OUT

	' Wait for the clock to go high again
	WAITPEQ   SCL_PIN, SCL_PIN
	WAITPEQ   ZERO, SCL_PIN

	' Set SDA back to input	
	ANDN      I2C_DIR, SDA_PIN
	MOV       DIRA, I2C_DIR

	ANDN      I2C_OUT, LED1
	MOV       OUTA, I2C_OUT
ACK_RET RET

'
' Pointers in hub memory
'
I2C_SERVO_0
	LONG 0

I2C_SHOULD_ECHO
	LONG 0

'
' Configurable constant registers
' 
MY_ADDR       LONG $D2  ' 0x69
SCL_PIN       LONG $020000
SDA_PIN       LONG $040000
LED0          LONG $8000
LED1          LONG $4000
LED2          LONG $2000
LED_MSK       LONG $E000

'
' Working memory registers
'
A1            LONG 0
RET_VAL       LONG 0
SDA_BIT       LONG 0
SCL_BIT       LONG 0
I2C_BYTE      LONG 0
ZERO          LONG 0
FIRST         LONG 0

I2C_MSK       LONG 0
I2C_DIR       LONG 0
I2C_OUT       LONG 0
I2C_TMP       LONG 0
I2C_LINE_ST   LONG 0
I2C_STATE     LONG 0 ' 0: data, 1: start, 2: stop
I2C_IS_SR     LONG 0

ADDR_FRAME    LONG 0 ' Dev addr mentioned by the master
SEL_REG       LONG 0 ' Selected register
IS_READ_MODE  LONG 0
COUNT         LONG 0
----------------------
FIT 496
