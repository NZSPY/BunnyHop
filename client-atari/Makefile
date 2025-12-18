# Makefile for BunnyHop Atari 8-bit Client

# Compiler and tools
CC = cc65
AS = ca65
LD = ld65
CL = cl65

# Target
TARGET = bunnyhop

# Source files
SOURCES = bunnyhop.c

# Compiler flags
CFLAGS = -t atari -O

# Build rules
all: $(TARGET).xex

$(TARGET).xex: $(SOURCES)
	$(CL) $(CFLAGS) -o $(TARGET).xex $(SOURCES)

clean:
	rm -f $(TARGET).xex *.o

.PHONY: all clean

# Note: To create an ATR disk image, use:
# dir2atr -b MyPicoDos404 bunnyhop.atr . bunnyhop.xex
