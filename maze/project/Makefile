NAME=project

all: project

clean:
	rm -rf project project.o

project: project.asm
	nasm -f elf -F dwarf -g project.asm
	gcc -g -m32 -o project project.o /usr/local/share/csc314/driver.c /usr/local/share/csc314/asm_io.o
