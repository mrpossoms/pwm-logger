' --------------------
' PWM Watcher routine
'
	ORG 0
PWM_WATCHER
	' Compute the start pin bit. The PAR register
	' tells the cog which pin it should be reading as
	' the start pin. It is assumed that the following 3 pins
	' are also input channels. The next 4 are outputs
	MOV           PWM_TMP, PAR
	SUB           PWM_TMP, PWM_SERVO_START
	SHR           PWM_TMP, #2

	MOV           PWM_IN_MSK, #1
	SHL           PWM_IN_MSK, PWM_TMP 
	MOV           PWM_OUT_MSK, PWM_IN_MSK
	SHL           PWM_OUT_MSK, #6
	
	' Set the output pins to... well, output
	MOV           PWM_DIR, DIRA
	OR            PWM_DIR, PWM_OUT_MSK
	ANDN          PWM_DIR, PWM_IN_MSK
	MOV           DIRA, PWM_DIR
	
	' Read from the hub at address 0
	' the long which indicates if a PWM passthrough
	' "echo" should be performed
	RDLONG        SHOULD_ECHO, PWM_SHOULD_ECHO

	' Compute pulse value address
	MOV           ADDR, PAR

:WATCHER_LOOP
	RDLONG        SHOULD_ECHO, PWM_SHOULD_ECHO

	' Echo pwm signal, this is conditional
	TJNZ          SHOULD_ECHO, #:ECHO_LOOP

:PWM_GEN_LOOP
	RDLONG        TIME, ADDR

	' Generate the pulse
	MOV           START, CNT
	ADD           START, TIME
	OR            PWM_OUT, PWM_OUT_MSK
	MOV           OUTA, PWM_OUT
	WAITCNT       START, #0
	ANDN          PWM_OUT, PWM_OUT_MSK
	MOV           OUTA, PWM_OUT

	' Wait for the remainder of the duty cycle
	MOV           START, CNT
	ADD           START, PWM_20MS
	SUB           START, TIME
	WAITCNT       START, #0

	JMP           #:WATCHER_LOOP

:ECHO_LOOP
	' Wait for pulse high
	WAITPEQ       PWM_IN_MSK, PWM_IN_MSK
	OR            PWM_OUT, PWM_OUT_MSK
	MOV           OUTA, PWM_OUT
	MOV           START, CNT

	' Wait for a low pulse
	WAITPEQ       PWM_ZERO, PWM_IN_MSK
	ANDN          PWM_OUT, PWM_OUT_MSK
	MOV           OUTA, PWM_OUT
	MOV           TIME, CNT

	' Compute the pulse time
	SUB           TIME, START
 
	' Sync with hub
	WRLONG        TIME, ADDR

	JMP           #:WATCHER_LOOP

PWM_SERVO_START
	LONG 0

PWM_SHOULD_ECHO
	LONG 0

ADDR          LONG 0
START         LONG 0
TIME          LONG 0
SHOULD_ECHO   LONG 0
PWM_TMP       LONG 0
PWM_IN_MSK    LONG 0
PWM_OUT_MSK   LONG 0
PWM_DIR       LONG 0
PWM_OUT       LONG 0
PWM_ZERO      LONG 0
PWM_20MS      LONG 1600000

'---------------------
	FIT 496