NAME=maze

all: maze

clean:
	rm -rf maze maze.o

maze: maze.asm
	nasm -f elf maze.asm
	gcc -g -m32 -o maze maze.o /usr/local/share/csc314/driver.c /usr/local/share/csc314/asm_io.o -lncurses
