' --------------------
' PWM Watcher routine
'
	ORG 0
PWM_WATCHER
	' Compute the start pin bit. The PAR register
	' tells the cog which pin it should be reading as
	' the start pin. It is assumed that the following 3 pins
	' are also input channels. The next 4 are outputs
	MOV in_pin_start, PAR
	MOV out_pin_start, PAR
	ADD out_pin_start, # 4
	
	' Set the output pins to... well, output
	MOV R1, #$F
	SHL R1, out_pin_start
	MOV DIRA, R1
	
	' Read from the hub at address 0
	' the long which indicates if a PWM passthrough
	' "echo" should be performed
	RDLONG SHOULD_ECHO, HUB_SHOULD_ECHO
	'MOV SHOULD_ECHO, #1

:WATCHER_LOOP
	MOV IN, INA   ' Keep the most recent state somewhere safe

	' Echo pwm signal, this is conditional
	TEST SHOULD_ECHO, #1 WZ
	IF_NZ MOV R1, IN
	IF_NZ SHL R1, #4
	IF_NZ MOV OUTA, R1

	' Set counters, point dest and src fields at the right
	' addresses
	MOV COUNTER, #4
	MOVD :SET_START_TIME, #START_TIMES + 4
	MOVS :FIND_WIDTH, #START_TIMES + 4
	MOVD :FIND_WIDTH + 1, #WIDTHS + 4
	MOV NEEDS_SYNC, #0
:EACH_PIN
	SUB COUNTER, #1
	MOV R1, IN
	SHR R1, COUNTER
	AND R1, #1
	
	MOV R2, LAST_IN
	SHR R2, COUNTER
	AND R2, #1
	ADD COUNTER, #1
	
	CMP R1, R2 WZ ' See if we have a rising edge
	' Z flag is set to 1 on rising edge

:SET_START_TIME
	' Rising edge was detected. Load the current cycle count
	' into the right spot in the START_TIMES vector
	IF_E MOV 0-0, CNT

	' Falling edge detected. Compute width in cycles 
	IF_NE MOV R1, CNT
:FIND_WIDTH
	IF_NE SUB R1, 0-0
	IF_NE MOV 0-0, R1
	IF_NE OR NEEDS_SYNC, #1

	' Modifiy the source and destination fields for
	' FIND_WIDTH and SET_START_TIME related instructions so
	' they point to the next respective values
	SUB  :SET_START_TIME, DEST_LSb 
	SUBS :FIND_WIDTH, #1
	SUB  :FIND_WIDTH + 1, DEST_LSb

	DJNZ COUNTER, #:EACH_PIN
	
	MOV LAST_IN, IN

:PWM_HUB_SYNC
	TJZ NEEDS_SYNC, #:WATCHER_LOOP
	' Sync up. Send widths to the hub
	MOV R1, #4
	SHL R1, out_pin_start
	WRLONG WIDTHS + 0, R1
	ADD R1, #4
	WRLONG WIDTHS + 1, R1
	ADD R1, #4
	WRLONG WIDTHS + 2, R1
	ADD R1, #4
	WRLONG WIDTHS + 3, R1

	'ADD DBG, #1
	'TEST DBG, #1 WZ
	'MOV R1, #$FF
	'SHL R1, #4
	'IF_E MOV OUTA, R1
	'IF_NE MOV OUTA, #0

	JMP #:WATCHER_LOOP

HUB_SHOULD_ECHO
	LONG 0
DBG           LONG 0
COUNTER       LONG 0
R1            LONG 0
R2            LONG 0
NEEDS_SYNC    LONG 0
DEST_LSb      LONG $200
SHOULD_ECHO   LONG 0
IN            LONG 0
LAST_IN       LONG 0
in_pin_start  LONG 0
out_pin_start LONG 0
START_TIMES   RES  4
WIDTHS        RES  4
'---------------------
	FIT 496
