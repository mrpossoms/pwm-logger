CC=propeller-elf-gcc
C_FLAGS= -std=c99 -mcog -g
INC=-Ilib/libsimpletools -Ilib/libsimpletext -Ilib/libsimplei2c
LIB=-Llib/libsimpletools/cmm -Llib/libsimpletext/cmm
LINK=-lm -lsimpletext
#SERIAL=cu.usbserial-*
SERIAL=/dev/ttyUSB0

#
all: out out/pwm.cog
	$(CC) $(INC) $(LIB) -o out/firmware.elf $(C_FLAGS) src/main.c out/pwm.cog $(LINK) 

out/pwm.cog: out
	propeller-elf-gcc -r -mcog $(C_FLAGS) -o out/pwm.cog -xc src/pwm.cogc
	propeller-elf-objcopy --localize-text --rename-section .text=pwm.cog out/pwm.cog

assemble: out
	$(CC) $(INC) $(LIB) -S $(C_FLAGS) src/main.c $(LINK)
#
out:
	@mkdir out

.PHONY: flash

check: all
	propeller-elf-objdump -h out/firmware.elf

flash: check
	propeller-load -p $(SERIAL) -S20 -I $(PROP_GCC)/propeller-load out/firmware.elf -r

run: flash
	screen $(SERIAL) 115200

clean:
	rm -rf out
