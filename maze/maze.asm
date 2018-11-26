%include "/usr/local/share/csc314/asm_io.inc"

%define TICK 100000

; the file that stores the initial state
%define BOARD_FILE 'board.txt'

; how to represent everything
%define WALL_CHAR '#'
%define GOLD_CHAR 'G'
%define PLAYER_CHAR 'O'
%define EMPTY_CHAR ' '

; the size of the game screen in characters
%define HEIGHT 41
%define WIDTH 41

; the player starting position.
; top left is considered (0,0)
%define STARTX 1
%define STARTY 1

; these keys do things
%define EXITCHAR 'x'
%define UPCHAR 'w'
%define LEFTCHAR 'a'
%define DOWNCHAR 's'
%define RIGHTCHAR 'd'


segment .data

	; used to fopen() the board file defined above
	board_file			db BOARD_FILE,0
	create_new_board	db "./create_new_board",0

	; used to change the terminal mode
	mode_r				db "r",0
	raw_mode_on_cmd		db "stty raw -echo",0
	raw_mode_off_cmd	db "stty -raw echo",0

	; called by system() to clear/refresh the screen
	clear_screen_cmd	db "clear",0

	SCORE				dd 10000
	SCORE_FMT			db	"SCORE: %d",13,10,0

	; things the program will print
	help_str			db 13,10,"Controls: ", \
							UPCHAR,"=UP / ", \
							LEFTCHAR,"=LEFT / ", \
							DOWNCHAR,"=DOWN / ", \
							RIGHTCHAR,"=RIGHT / ", \
							EXITCHAR,"=EXIT", \
							13,10,10,0
	gold_count		dd		0
	gold_fmt		db		"Gold: %d",13,10,0
segment .bss

	; this array stores the current rendered gameboard (HxW)
	board	resb	(HEIGHT * WIDTH)

	; these variables store the current player position
	xpos	resd	1
	ypos	resd	1

segment .text

	global	asm_main
	extern	system
	extern	putchar
	extern	getchar
	extern	printf
	extern	fopen
	extern	fread
	extern	fgetc
	extern	fclose
	extern  time
	extern  srand
	extern  rand
	extern  usleep
	extern  fcntl
	extern  system
	extern  getch

asm_main:
	enter	0,0
	pusha
	;***************CODE STARTS HERE***************************

	call getch

	push create_new_board
	call system
	add esp, 4

	;RANDOM NUMBERS
	;srand(time(0));
	push 0
	call time
	add  esp, 4

	push eax
	call srand
	add  esp, 4
	;eax = rand() % 50;
	call rand

	cdq
	mov  edx, 50
	idiv ebx
	;edx = 0-49




	; put the terminal in raw mode so the game works nicely
	call	raw_mode_on

	; read the game board file into the global variable
	call	init_board

	; set the player at the proper start position
	mov		DWORD [xpos], STARTX
	mov		DWORD [ypos], STARTY

	; the game happens in this loop
	; the steps are...
	;   1. render (draw) the current board
	;   2. get a character from the user
	;	3. store current xpos,ypos in esi,edi
	;	4. update xpos,ypos based on character from user
	;	5. check what's in the buffer (board) at new xpos,ypos
	;	6. if it's a wall, reset xpos,ypos to saved esi,edi
	;	7. otherwise, just continue! (xpos,ypos are ok)
	game_loop:
		push TICK
		call usleep
		add  esp, 4
		; draw the game board
		call	render

		; get an action from the user
		call	nonblocking_getchar

		cmp		al, -1
		jne		got_char
			dec DWORD [SCORE]
			jmp game_loop
		got_char:

		add DWORD [SCORE], 100

		; store the current position
		; we will test if the new position is legal
		; if not, we will restore these
		mov		esi, [xpos]
		mov		edi, [ypos]

		; choose what to do
		cmp		eax, EXITCHAR
		je		game_loop_end
		cmp		eax, UPCHAR
		je 		move_up
		cmp		eax, LEFTCHAR
		je		move_left
		cmp		eax, DOWNCHAR
		je		move_down
		cmp		eax, RIGHTCHAR
		je		move_right
		jmp		input_end			; or just do nothing

		; move the player according to the input character
		move_up:
			dec		DWORD [ypos]
			jmp		input_end
		move_left:
			dec		DWORD [xpos]
			jmp		input_end
		move_down:
			inc		DWORD [ypos]
			jmp		input_end
		move_right:
			inc		DWORD [xpos]
		input_end:

		; (W * y) + x = pos

		; compare the current position to the wall character
		mov		eax, WIDTH
		mul		DWORD [ypos]
		add		eax, [xpos]
		lea		eax, [board + eax]
		cmp		BYTE [eax], WALL_CHAR
		jne		valid_move
			; opps, that was an invalid move, reset
			mov		DWORD [xpos], esi
			mov		DWORD [ypos], edi
		valid_move:
			cmp	BYTE[eax], GOLD_CHAR
			jne not_gold
				inc	DWORD [gold_count]
				mov	BYTE[eax], EMPTY_CHAR
		not_gold:
	jmp		game_loop
	game_loop_end:

	; restore old terminal functionality
	call raw_mode_off

	;***************CODE ENDS HERE*****************************
	popa
	mov		eax, 0
	leave
	ret

; === FUNCTION ===
raw_mode_on:

	push	ebp
	mov		ebp, esp

	push	raw_mode_on_cmd
	call	system
	add		esp, 4

	mov		esp, ebp
	pop		ebp
	ret

; === FUNCTION ===
raw_mode_off:

	push	ebp
	mov		ebp, esp

	push	raw_mode_off_cmd
	call	system
	add		esp, 4

	mov		esp, ebp
	pop		ebp
	ret

; === FUNCTION ===
init_board:

	push	ebp
	mov		ebp, esp

	; FILE* and loop counter
	; ebp-4, ebp-8
	sub		esp, 8

	; open the file
	push	mode_r
	push	board_file
	call	fopen
	add		esp, 8
	mov		DWORD [ebp-4], eax

	; read the file data into the global buffer
	; line-by-line so we can ignore the newline characters
	mov		DWORD [ebp-8], 0
	read_loop:
	cmp		DWORD [ebp-8], HEIGHT
	je		read_loop_end

		; find the offset (WIDTH * counter)
		mov		eax, WIDTH
		mul		DWORD [ebp-8]
		lea		ebx, [board + eax]

		; read the bytes into the buffer
		push	DWORD [ebp-4]
		push	WIDTH
		push	1
		push	ebx
		call	fread
		add		esp, 16

		; slurp up the newline
		push	DWORD [ebp-4]
		call	fgetc
		add		esp, 4

	inc		DWORD [ebp-8]
	jmp		read_loop
	read_loop_end:

	; close the open file handle
	push	DWORD [ebp-4]
	call	fclose
	add		esp, 4

	mov		esp, ebp
	pop		ebp
	ret

; === FUNCTION ===
render:

	push	ebp
	mov		ebp, esp

	; two ints, for two loop counters
	; ebp-4, ebp-8
	sub		esp, 8

	; clear the screen
	push	clear_screen_cmd
	call	system
	add		esp, 4

	; print the help information
	push	help_str
	call	printf
	add		esp, 4

	push	DWORD [gold_count]
	push	gold_fmt
	call	printf
	add		esp, 8

	push DWORD[SCORE]
	push SCORE_FMT
	call printf
	add esp, 8

	; outside loop by height
	; i.e. for(c=0; c<height; c++)
	mov		DWORD [ebp-4], 0
	y_loop_start:
	cmp		DWORD [ebp-4], HEIGHT
	je		y_loop_end

		; inside loop by width
		; i.e. for(c=0; c<width; c++)
		mov		DWORD [ebp-8], 0
		x_loop_start:
		cmp		DWORD [ebp-8], WIDTH
		je 		x_loop_end

			; check if (xpos,ypos)=(x,y)
			mov		eax, [xpos]
			cmp		eax, DWORD [ebp-8]
			jne		print_board
			mov		eax, [ypos]
			cmp		eax, DWORD [ebp-4]
			jne		print_board
				; if both were equal, print the player
				push	PLAYER_CHAR
				jmp		print_end
			print_board:
				; otherwise print whatever's in the buffer
				mov		eax, [ebp-4]
				mov		ebx, WIDTH
				mul		ebx
				add		eax, [ebp-8]
				mov		ebx, 0
				mov		bl, BYTE [board + eax]
				push	ebx
			print_end:
			call	putchar
			add		esp, 4

		inc		DWORD [ebp-8]
		jmp		x_loop_start
		x_loop_end:

		; write a carriage return (necessary when in raw mode)
		push	0x0d
		call 	putchar
		add		esp, 4

		; write a newline
		push	0x0a
		call	putchar
		add		esp, 4

	inc		DWORD [ebp-4]
	jmp		y_loop_start
	y_loop_end:

	mov		esp, ebp
	pop		ebp
	ret




nonblocking_getchar:

; returns -1 on no-data
; returns char on succes

; magic values
%define F_GETFL 3
%define F_SETFL 4
%define O_NONBLOCK 2048
%define STDIN 0

	push	ebp
	mov		ebp, esp

	; single int used to hold flags
	; single character (aligned to 4 bytes) return
	sub		esp, 8

	; get current stdin flags
	; flags = fcntl(stdin, F_GETFL, 0)
	push	0
	push	F_GETFL
	push	STDIN
	call	fcntl
	add		esp, 12
	mov		DWORD [ebp-4], eax

	; set non-blocking mode on stdin
	; fcntl(stdin, F_SETFL, flags | O_NONBLOCK)
	or		DWORD [ebp-4], O_NONBLOCK
	push	DWORD [ebp-4]
	push	F_SETFL
	push	STDIN
	call	fcntl
	add		esp, 12

	call	getchar
	mov		DWORD [ebp-8], eax

	; restore blocking mode
	; fcntl(stdin, F_SETFL, flags ^ O_NONBLOCK
	xor		DWORD [ebp-4], O_NONBLOCK
	push	DWORD [ebp-4]
	push	F_SETFL
	push	STDIN
	call	fcntl
	add		esp, 12

	mov		eax, DWORD [ebp-8]

	mov		esp, ebp
	pop		ebp
	ret