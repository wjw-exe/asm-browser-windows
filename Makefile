# Windows build (run on Windows with MSYS2/MinGW-w64, or on Linux with
# mingw-w64 cross toolchain installed):
#   make
# Produces browser.exe (console). The Tk GUI drives it via stdio pipe.
CC ?= x86_64-w64-mingw32-gcc
CFLAGS += -O0 -Wall
LIBS   += -lkernel32 -lws2_32

all: browser.exe

browser.exe: win/kernel.S
	$(CC) $(CFLAGS) -o $@ $< $(LIBS)

run: browser.exe
	./browser.exe

clean:
	-rm -f browser.exe *.o
.PHONY: all run clean
