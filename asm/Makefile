pwm-logger: hub.s i2c-cog.s pwm-cog.s
	openspin -v -b -o pwm-logger hub.s

flash: pwm-logger
	propeller-load -p/dev/ttyUSB0 -r pwm-logger
