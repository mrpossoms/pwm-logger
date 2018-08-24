'
' This file is part of pwm-logger
'
' pwm-logger is free software: you can redistribute it and/or modify
' it under the terms of the GNU General Public License as published by
' the Free Software Foundation, either version 3 of the License, or
' (at your option) any later version.
'
' This program is distributed in the hope that it will be useful,
' but WITHOUT ANY WARRANTY; without even the implied warranty of
' MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
' GNU General Public License for more details.
'
' You should have received a copy of the GNU General Public License
' along with this program.  If not, see <http://www.gnu.org/licenses/>.
'

' --------------------
' PWM Watcher routine
'
	ORG 0
PWM_WATCHER
	' Compute the start pin bit. The PAR register
	' tells the cog which pin it should be reading as
	' the start pin. It is assumed that the following 3 pins
	' are also input channels. The next 4 are outputs
	MOV           PWM_TMP_0, PAR
	SUB           PWM_TMP_0, PWM_SERVO_START

	' convert from address space to an index
	SHR           PWM_TMP_0, #2
	MOV           PWM_IDX, PWM_TMP_0

	' Shift to the next 4 pins if this cog is watching > channel 3
	CMP           PWM_TMP_0, #3 WZ, WC
	IF_NC_AND_NZ ADD  PWM_TMP_0, #4

	' Compute the input and output masks
	MOV           PWM_IN_MSK, #1
	SHL           PWM_IN_MSK, PWM_TMP_0
	MOV           PWM_OUT_MSK, PWM_IN_MSK
	SHL           PWM_OUT_MSK, #4

	' Set the output pins to output, and the input to input
	MOV           PWM_DIR, DIRA
	OR            PWM_DIR, PWM_OUT_MSK
	ANDN          PWM_DIR, PWM_IN_MSK
	MOV           DIRA, PWM_DIR

	' Read from the hub at address 0
	' the long which indicates if a PWM passthrough
	' "echo" should be performed
	RDLONG        SHOULD_ECHO, PWM_SHOULD_ECHO

	' Compute pulse value addresses
	MOV           ADDR, PAR
	MOV           REC_ADDR, PWM_REC_SERVO_START
	MOV           PWM_TMP_0, PWM_IDX
	SHL           PWM_TMP_0, #2
	ADD           REC_ADDR, PWM_TMP_0

:WATCHER_LOOP
	' Select out the bit for the channel this cog is handling
	RDLONG        SHOULD_ECHO, PWM_SHOULD_ECHO
	SHR           SHOULD_ECHO, PWM_IDX
	AND           SHOULD_ECHO, #1

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

	' Measure the signal from the reciever and store it
	WAITPEQ       PWM_IN_MSK, PWM_IN_MSK
	MOV           PWM_TMP_0, CNT
	WAITPEQ       PWM_ZERO, PWM_IN_MSK
	MOV           PWM_TMP_1, CNT
	SUB           PWM_TMP_1, PWM_TMP_0
	WRLONG        PWM_TMP_1, REC_ADDR

	' Wait for the remainder of the duty cycle
	MOV           START, CNT
	ADD           START, PWM_20MS
	SUB           START, TIME
	WAITCNT       START, #0

	' If we are generating a signal, we also want to watch
	' the reciever lines and save those values seperately
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
	WRLONG        TIME, REC_ADDR

	JMP           #:WATCHER_LOOP


PWM_SERVO_START
	LONG 0

PWM_REC_SERVO_START
	LONG 0

PWM_SHOULD_ECHO
	LONG 0

P_LED0          LONG $040000
P_LED1          LONG $080000
P_LED2          LONG $100000

ADDR          LONG 0
REC_ADDR      LONG 0
START         LONG 0
TIME          LONG 0
SHOULD_ECHO   LONG 0
PWM_TMP_0     LONG 0
PWM_TMP_1     LONG 0
PWM_IN_MSK    LONG 0
PWM_OUT_MSK   LONG 0
PWM_DIR       LONG 0
PWM_OUT       LONG 0
PWM_IDX       LONG 0
PWM_ZERO      LONG 0
PWM_20MS      LONG 1600000

'---------------------
	FIT 496
