# Arduino makefile
#
# This makefile allows you to build sketches from the command line
# without the Arduino environment (or Java).
#
# The Arduino environment does preliminary processing on a sketch before
# compiling it.  If you're using this makefile instead, you'll need to do
# a few things differently:
#
#   - Give your program's file a .cpp extension (e.g. foo.cpp).
#
#   - Put this line at top of your code: #include <WProgram.h>
#
#   - Write prototypes for all your functions (or define them before you
#     call them).  A prototype declares the types of parameters a
#     function will take and what type of value it will return.  This
#     means that you can have a call to a function before the definition
#     of the function.  A function prototype looks like the first line of
#     the function, with a semi-colon at the end.  For example:
#     int digitalRead(int pin);
#
#   - Write a main() function for your program that returns an int, calls
#     init() and setup() once (in that order), and then calls loop()
#     repeatedly():
#
#	int main()
#	{
#		init();
#		setup();
#
#		for (;;)
#			loop();
#
#		return 0;
#	}
#
# Instructions for using the makefile:
#
#  1. Copy this file into the folder with your sketch.
#
#  2. Below, modify the line containing "TARGET" to refer to the name of
#     of your program's file without an extension (e.g. TARGET = foo).
#
#  3. Modify the line containg "ARDUINO" to point the directory that
#     contains the Arduino core (for normal Arduino installations, this
#     is the hardware/cores/arduino sub-directory).
#
#  4. Modify the line containing "PORT" to refer to the filename
#     representing the USB or serial connection to your Arduino board
#     (e.g. PORT = /dev/tty.USB0).  If the exact name of this file
#     changes, you can use * as a wildcard (e.g. PORT = /dev/tty.USB*).
#
#  5. At the command line, change to the directory containing your
#     program's file and the makefile.
#
#  6. Type "make" and press enter to compile/verify your program.
#
#  7. Type "make upload", reset your Arduino board, and press enter  to
#     upload your program to the Arduino board.
#
# $Id$

# Update these to reflect the location of the Arduino IDE and avrdude installations, respectively
ARDUINO = /Applications/arduino-0013/hardware/cores/arduino/
AVRDUDE_DIR = /usr/local/AVRMacPack/bin/
LIBRARIES = /Applications/arduino-0013/hardware/libraries/Servo/

PORT = /dev/tty.usbserial*
TARGET = main
SRC = $(ARDUINO)/pins_arduino.c $(ARDUINO)/wiring.c \
$(ARDUINO)/wiring_analog.c $(ARDUINO)/wiring_digital.c \
$(ARDUINO)/wiring_pulse.c $(ARDUINO)/wiring_serial.c \
$(ARDUINO)/wiring_shift.c $(ARDUINO)/WInterrupts.c
CXXSRC = $(ARDUINO)/HardwareSerial.cpp $(ARDUINO)/WMath.cpp $(ARDUINO)/Print.cpp $(LIBRARIES)/Servo.cpp
MCU = atmega168
F_CPU = 16000000
FORMAT = ihex
UPLOAD_RATE = 19200

# Name of this Makefile (used for "make depend").
MAKEFILE = Makefile

# Debugging format.
# Native formats for AVR-GCC's -g are stabs [default], or dwarf-2.
# AVR (extended) COFF requires stabs, plus an avr-objcopy run.
DEBUG = stabs

OPT = s

# Place -D or -U options here
CDEFS = -DF_CPU=$(F_CPU)
CXXDEFS = -DF_CPU=$(F_CPU)

# Place -I options here
CINCS = -I$(ARDUINO) -I$(LIBRARIES)
CXXINCS = -I$(ARDUINO) -I$(LIBRARIES)

# Compiler flag to set the C Standard level.
# c89   - "ANSI" C
# gnu89 - c89 plus GCC extensions
# c99   - ISO C99 standard (not yet fully implemented)
# gnu99 - c99 plus GCC extensions
CSTANDARD = -std=gnu99
CDEBUG = -g$(DEBUG)
CWARN = -Wall -Wstrict-prototypes
CTUNING = -funsigned-char -funsigned-bitfields -fpack-struct -fshort-enums
#CEXTRA = -Wa,-adhlns=$(<:.c=.lst)

CFLAGS = $(CDEBUG) $(CDEFS) $(CINCS) -O$(OPT) $(CWARN) $(CSTANDARD) $(CEXTRA)
CXXFLAGS = $(CDEFS) $(CINCS) -O$(OPT)
#ASFLAGS = -Wa,-adhlns=$(<:.S=.lst),-gstabs 
LDFLAGS = -lm


# Programming support using avrdude. Settings and variables.
AVRDUDE_PROGRAMMER = stk500
AVRDUDE_PORT = $(PORT)
AVRDUDE_WRITE_FLASH = -U flash:w:$(TARGET).hex
AVRDUDE_FLAGS = -F -p $(MCU) -P $(AVRDUDE_PORT) -c $(AVRDUDE_PROGRAMMER) \
  -b $(UPLOAD_RATE)
  

# Program settings
CC = $(AVRDUDE_DIR)/avr-gcc
CXX = $(AVRDUDE_DIR)/avr-g++
OBJCOPY = $(AVRDUDE_DIR)/avr-objcopy
OBJDUMP = $(AVRDUDE_DIR)/avr-objdump
AR  = $(AVRDUDE_DIR)/avr-ar
SIZE = $(AVRDUDE_DIR)/avr-size
NM = $(AVRDUDE_DIR)/avr-nm
AVRDUDE = $(AVRDUDE_DIR)/avrdude
REMOVE = rm -f
MV = mv -f

# Define all object files.
OBJ = $(SRC:.c=.o) $(CXXSRC:.cpp=.o) $(ASRC:.S=.o)

# Define all listing files.
LST = $(ASRC:.S=.lst) $(CXXSRC:.cpp=.lst) $(SRC:.c=.lst)

# Combine all necessary flags and optional flags.
# Add target processor to flags.
ALL_CFLAGS = -mmcu=$(MCU) -I. $(CFLAGS)
ALL_CXXFLAGS = -mmcu=$(MCU) -I. $(CXXFLAGS)
ALL_ASFLAGS = -mmcu=$(MCU) -I. -x assembler-with-cpp $(ASFLAGS)


# Default target.
all: build

build: elf hex

elf: $(TARGET).elf
hex: $(TARGET).hex
eep: $(TARGET).eep
lss: $(TARGET).lss 
sym: $(TARGET).sym

# Program the device.  
upload: $(TARGET).hex
	$(AVRDUDE) $(AVRDUDE_FLAGS) $(AVRDUDE_WRITE_FLASH)




# Convert ELF to COFF for use in debugging / simulating in AVR Studio or VMLAB.
COFFCONVERT=$(OBJCOPY) --debugging \
--change-section-address .data-0x800000 \
--change-section-address .bss-0x800000 \
--change-section-address .noinit-0x800000 \
--change-section-address .eeprom-0x810000 


coff: $(TARGET).elf
	$(COFFCONVERT) -O coff-avr $(TARGET).elf $(TARGET).cof


extcoff: $(TARGET).elf
	$(COFFCONVERT) -O coff-ext-avr $(TARGET).elf $(TARGET).cof


.SUFFIXES: .elf .hex .eep .lss .sym

.elf.hex:
	$(OBJCOPY) -O $(FORMAT) -R .eeprom $< $@

.elf.eep:
	-$(OBJCOPY) -j .eeprom --set-section-flags=.eeprom="alloc,load" \
	--change-section-lma .eeprom=0 -O $(FORMAT) $< $@

# Create extended listing file from ELF output file.
.elf.lss:
	$(OBJDUMP) -h -S $< > $@

# Create a symbol table from ELF output file.
.elf.sym:
	$(NM) -n $< > $@


core.a: $(OBJ)
	@for i in $(OBJ); do echo $(AR) rcs core.a $$i; $(AR) rcs core.a $$i; done

# Link: create ELF output file from library.
$(TARGET).elf: core.a
	$(CC) $(ALL_CFLAGS) -o $@ $(TARGET).cpp -L. core.a $(LDFLAGS)

# Compile: create object files from C++ source files.
.cpp.o:
	$(CXX) -c $(ALL_CXXFLAGS) $< -o $@ 

# Compile: create object files from C source files.
.c.o:
	$(CC) -c $(ALL_CFLAGS) $< -o $@ 


# Compile: create assembler files from C source files.
.c.s:
	$(CC) -S $(ALL_CFLAGS) $< -o $@


# Assemble: create object files from assembler source files.
.S.o:
	$(CC) -c $(ALL_ASFLAGS) $< -o $@



# Target: clean project.
clean:
	$(REMOVE) $(TARGET).hex $(TARGET).eep $(TARGET).cof $(TARGET).elf \
	$(TARGET).map $(TARGET).sym $(TARGET).lss core.a \
	$(OBJ) $(LST) $(SRC:.c=.s) $(SRC:.c=.d) $(CXXSRC:.cpp=.s) $(CXXSRC:.cpp=.d)

depend:
	if grep '^# DO NOT DELETE' $(MAKEFILE) >/dev/null; \
	then \
		sed -e '/^# DO NOT DELETE/,$$d' $(MAKEFILE) > \
			$(MAKEFILE).$$$$ && \
		$(MV) $(MAKEFILE).$$$$ $(MAKEFILE); \
	fi
	echo '# DO NOT DELETE THIS LINE -- make depend depends on it.' \
		>> $(MAKEFILE); \
	$(CC) -M -mmcu=$(MCU) $(CDEFS) $(CINCS) $(SRC) $(ASRC) >> $(MAKEFILE)

.PHONY:	all build elf hex eep lss sym program coff extcoff clean depend
