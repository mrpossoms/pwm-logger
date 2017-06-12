CC=propeller-elf-gcc
C_FLAGS= -m32bit-doubles -Os -mcmm -std=c99 -s
INC=-Ilib/libsimpletools -Ilib/libsimpletext -Ilib/libsimplei2c
LIB=-Llib/libsimpletools/cmm -Llib/libsimpletext/cmm
LINK=-lm -lsimpletext
#SERIAL=cu.usbserial-*
SERIAL=/dev/ttyUSB0

#
all: out
	$(CC) $(INC) $(LIB) -o out/firmware.elf $(C_FLAGS) src/main.c $(LINK)
#
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
	rm out/*.o out/*.elf out/*.binary
