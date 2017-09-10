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
' Rotary encoder Watcher routine
'
	ORG 0
ROTARY_WATCHER
	MOV      ROTOR_STATE, INA
	AND      ROTOR_STATE, ROTOR_MSK

:ROTOR_LOOP
	WAITPNE  ROTOR_STATE, ROTOR_MSK

	MOV      ROTOR_TMP,   CNT
	ADD      ROTOR_TMP,   ROTOR_10MS
	WAITCNT  ROTOR_TMP,   #0

	MOV      ROTOR_STATE, INA
	AND      ROTOR_STATE, ROTOR_MSK

	ADD      ROTOR_COUNT, #1
	WRLONG   ROTOR_COUNT, ROTOR_COUNT_PTR

	JMP      #:ROTOR_LOOP



'	
' Registers
'
ROTOR_COUNT_PTR
	LONG 0

ROTOR_10MS   LONG 800000
ROTOR_STATE LONG 0
ROTOR_COUNT LONG 0
ROTOR_MSK   LONG $00000800
ROTOR_TMP   LONG 0

'---------------------
	FIT 496
