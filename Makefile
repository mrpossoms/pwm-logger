PORT=/dev/cu.usbserial-AK04L6BW

pwm-logger: hub.s i2c-cog.s pwm-cog.s
	openspin -v -b -o pwm-logger hub.s

flash: pwm-logger
	propeller-load -p$(PORT) -r pwm-logger
