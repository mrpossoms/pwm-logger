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

_CLKMODE = XTAL1 + PLL16X
_CLKFREQ = 80_000_000

VAR
	LONG HUB_SERVO_0
	LONG HUB_SERVO_1
	LONG HUB_SERVO_2
	LONG HUB_SERVO_3
	LONG HUB_SERVO_4
	LONG HUB_SERVO_5
	LONG HUB_SERVO_6
	LONG HUB_SERVO_7
	LONG HUB_REC_SERVO_0
	LONG HUB_REC_SERVO_1
	LONG HUB_REC_SERVO_2
	LONG HUB_REC_SERVO_3
	LONG HUB_REC_SERVO_4
	LONG HUB_REC_SERVO_5
	LONG HUB_REC_SERVO_6
	LONG HUB_REC_SERVO_7
	LONG HUB_ROTOR_COUNT
	LONG HUB_SHOULD_ECHO
	LONG HUB_FIRMWARE_VERSION

PUB main

	HUB_SHOULD_ECHO      := $ff
	HUB_FIRMWARE_VERSION := 1
	
	PWM_SHOULD_ECHO      := @HUB_SHOULD_ECHO
	PWM_SERVO_START      := @HUB_SERVO_0
	PWM_REC_SERVO_START  := @HUB_REC_SERVO_0

	I2C_SHOULD_ECHO      := @HUB_SHOULD_ECHO
	I2C_SERVO_0          := @HUB_SERVO_0
	I2C_REC_SERVO_0      := @HUB_REC_SERVO_0
	I2C_FIRMWARE_VERSION := @HUB_FIRMWARE_VERSION
	I2C_ROTOR_COUNT      := @HUB_ROTOR_COUNT
	
	ROTOR_COUNT_PTR      := @HUB_ROTOR_COUNT

   	cognew(@I2C_DRIVER, 0)
   	cognew(@ROTARY_WATCHER, 0)
   	cognew(@PWM_WATCHER, @HUB_SERVO_1)
   	cognew(@PWM_WATCHER, @HUB_SERVO_2)

DAT
#include "pwm-cog.s"
#include "i2c-cog.s"
#include "rot-enc-cog.s"
