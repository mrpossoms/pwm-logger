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
	LONG HUB_SHOULD_ECHO
	LONG HUB_FIRMWARE_VERSION
	LONG HUB_SERVO_0
	LONG HUB_SERVO_1
	LONG HUB_SERVO_2
	LONG HUB_SERVO_3
	LONG HUB_SERVO_4
	LONG HUB_SERVO_5
	LONG HUB_SERVO_6
	LONG HUB_SERVO_7

PUB main

	HUB_SHOULD_ECHO      := 1
	HUB_FIRMWARE_VERSION := 1
	PWM_SHOULD_ECHO      := @HUB_SHOULD_ECHO
	I2C_SHOULD_ECHO      := @HUB_SHOULD_ECHO
	I2C_SERVO_0          := @HUB_SERVO_0
	PWM_SERVO_START      := @HUB_SERVO_0
	I2C_FIRMWARE_VERSION := @HUB_FIRMWARE_VERSION
   	cognew(@I2C_DRIVER, 0)
   	'cognew(@PWM_WATCHER, @HUB_SERVO_2)
   	'cognew(@PWM_WATCHER, @HUB_SERVO_3)
   	cognew(@PWM_WATCHER, @HUB_SERVO_4)
   	cognew(@PWM_WATCHER, @HUB_SERVO_5)
   	cognew(@PWM_WATCHER, @HUB_SERVO_6)
   	cognew(@PWM_WATCHER, @HUB_SERVO_7)

DAT
#include "pwm-cog.s"
#include "i2c-cog.s"
