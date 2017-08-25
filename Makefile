#PORT=-p/dev/cu.usbserial-AK04L6BW
PORT=-p /dev/ttyUSB0

pwm-logger: hub.s i2c-cog.s pwm-cog.s rot-enc-cog.s
	openspin -v -b -o pwm-logger hub.s

load: pwm-logger
	propeller-load $(PORT) -r pwm-logger

flash: pwm-logger
	propeller-load $(PORT) -r pwm-logger -e
