all:
	openspin -v -b -o pwm-logger hub.s

flash:
	propeller-load -p/dev/ttyUSB0 -r pwm-logger
