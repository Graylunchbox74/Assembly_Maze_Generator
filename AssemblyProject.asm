%include "/usr/local/share/csc314/asm_io.inc"

segment .data
    DISPLAY_SIZE    dd  23
    MAX_STACK_SIZE  dd  1000
    EMPTY_CHAR      db  32
    WALL_CHAR       db  "#"
    stack_size      dd  0
    STEP_SIZE       dd  2
segment .bss

    display_arr    resb     10000
    stack_x_arr    resd     1000
    stack_y_arr    resd     1000
    stack_d_arr    resd     1000

segment .text
    global asm_main
    extern srand
    extern rand
    extern time
asm_main:
    push    ebp
    mov     ebp, esp

    push 0
    call time
    add  esp, 4

    push eax
    call srand
    add  esp, 4

    call clear_display
    push 1
    push 1
    call generate_maze
    add esp, 8
    call display
    mov     eax, 0
    mov     esp, ebp
    pop     ebp
    ret


clear_display:
    push    ebp
    mov     ebp, esp

        sub esp, 8
        mov DWORD[ebp-4],0
        mov DWORD[ebp-8],0
        top_clear_display_first:
            mov ebx, DWORD[ebp-4]
            cmp ebx, DWORD[DISPLAY_SIZE]
            jge bot_clear_display_first
	        mov DWORD[ebp-8],0

            top_clear_display_second:
                mov ebx, DWORD[ebp-8]
                cmp ebx, DWORD[DISPLAY_SIZE]
                jge bot_clear_display_second

                mov eax, DWORD[DISPLAY_SIZE]
                mov ecx, DWORD[ebp-4]
				mul	ecx
				mov	ebx, eax
                mov edx, DWORD[ebp-8]
                mov al, BYTE[WALL_CHAR]
                mov BYTE[ebx + edx + display_arr], al

                inc DWORD[ebp-8]
                jmp top_clear_display_second
            bot_clear_display_second:

            inc DWORD[ebp-4]
            jmp top_clear_display_first
        bot_clear_display_first:

    mov     esp, ebp
    pop     ebp
    ret

display:
    push    ebp
    mov     ebp, esp

        sub esp, 8
        mov DWORD[ebp-4],0
        mov DWORD[ebp-8],0
        top_display_first:
            mov ebx, DWORD[ebp-4]
            cmp ebx, DWORD[DISPLAY_SIZE]
            jge bot_display_first
	        mov DWORD[ebp-8],0

            top_display_second:
                mov ebx, DWORD[ebp-8]
                cmp ebx, DWORD[DISPLAY_SIZE]
                jge bot_display_second

                mov eax, DWORD[DISPLAY_SIZE]
                mov ecx, DWORD[ebp-4]
				mul	ecx
				mov	ebx, eax
                mov edx, DWORD[ebp-8]
                mov al, BYTE[WALL_CHAR]
                mov al, BYTE[ebx + edx + display_arr]
                call print_char

                inc DWORD[ebp-8]
                jmp top_display_second
            bot_display_second:
            mov al, 10
            call print_char
            inc DWORD[ebp-4]
            jmp top_display_first
        bot_display_first:

    mov     esp, ebp
    pop     ebp
    ret

set_pixel: 
    push    ebp
    mov     ebp, esp
    ;ebp + 8 = c
    ;ebp + 12 = y
    ;ebp + 16 = x

    mov ebx, DWORD[ebp+12]
    mov ecx, DWORD[ebp+16]
    push ebx
    push ecx
    call in_bounds
    add esp, 8

    ;if eax == 0 return
    cmp eax, 0
    jne set_pixel_true
        mov     esp, ebp
        pop     ebp
        ret

    set_pixel_true:

        mov eax, DWORD[DISPLAY_SIZE]
        mov ecx, DWORD[ebp+12]
		mul	ecx
		mov	ebx, eax
        mov edx, DWORD[ebp+16]
        ;mov eax, DWORD[ebp+8]
        mov al, BYTE[ebp+8]
        mov BYTE[ebx + edx + display_arr], al

    mov     esp, ebp
    pop     ebp
    ret


is_pixel:
    push    ebp
    mov     ebp, esp

    ;ebp + 8 = c
    ;ebp + 12 = y
    ;ebp + 16 = x

    mov ebx, DWORD[ebp+12]
    mov ecx, DWORD[ebp+16]
    push ebx
    push ecx
    call in_bounds
    add esp, 8

    ;if eax == 0 return
    cmp eax, 0
    jne is_pixel_true
        mov     esp, ebp
        pop     ebp
        ret

    is_pixel_true:
        mov eax, DWORD[DISPLAY_SIZE]
        mov ecx, DWORD[ebp+12]
		mul	ecx
		mov	ebx, eax
        mov edx, DWORD[ebp+16]
        mov al, BYTE[ebp+8]
        cmp BYTE[ebx + edx + display_arr], al
        jne is_pixel_not_true

            mov eax, 1

            mov     esp, ebp
            pop     ebp
            ret

        is_pixel_not_true:
            mov eax, 0

    mov     esp, ebp
    pop     ebp
    ret

in_bounds:
    push    ebp
    mov     ebp, esp
    ;ebp + 8 = y
    ;ebp + 12 = x

    mov eax, 0
    cmp DWORD[ebp + 12], eax
    jl  in_bounds_false
        mov eax, DWORD[DISPLAY_SIZE]
        cmp DWORD[ebp + 12], eax
        jge in_bounds_false
            mov eax, 0
            cmp DWORD[ebp + 8], eax
            jl  in_bounds_false
                mov eax, DWORD[DISPLAY_SIZE]
                cmp DWORD[ebp + 8], eax
                jge in_bounds_false
                    mov eax, 1
                    mov     esp, ebp
                    pop     ebp
                    ret
    in_bounds_false:
    mov eax, 0
    mov     esp, ebp
    pop     ebp
    ret

add_to_stack:
    push    ebp
    mov     ebp, esp
    ;ebp + 8 = d
    ;ebp + 12 = y
    ;ebp + 16 = x

    mov eax, DWORD[stack_size]
    mov ebx, DWORD[MAX_STACK_SIZE]
    cmp eax, ebx
    jl      add_to_stack_false
        mov eax, 1
        mov     esp, ebp
        pop     ebp
        ret
    add_to_stack_false:
    mov eax, DWORD[ebp+16]
    mov ebx, DWORD[stack_size]
    mov DWORD[stack_x_arr + ebx], eax

    mov eax, DWORD[ebp+12]
    mov ebx, DWORD[stack_size]
    mov DWORD[stack_y_arr + ebx], eax

    mov eax, DWORD[ebp+8]
    mov ebx, DWORD[stack_size]
    mov DWORD[stack_d_arr + ebx], eax

    inc DWORD[stack_size]

    mov eax, 0

    mov     esp, ebp
    pop     ebp
    ret

top_of_stack:
    push    ebp
    mov     ebp, esp

    ; eax = *x
    ; ebx = *y
    ; ecx = *d
    mov esi, DWORD[stack_size]
    dec esi
    mov eax, DWORD[stack_x_arr + esi]
    mov ebx, DWORD[stack_y_arr + esi]
    mov ecx, DWORD[stack_d_arr + esi]

    mov     esp, ebp
    pop     ebp
    ret 


pop_off_stack:
    push    ebp
    mov     ebp, esp

    dec     DWORD[stack_size]

    mov     esp, ebp
    pop     ebp
    ret 


clear_stack:
    push    ebp
    mov     ebp, esp   

    mov DWORD[stack_size],0

    mov     esp, ebp
    pop     ebp
    ret 


is_stack_empty:
    push    ebp
    mov     ebp, esp  

    mov     eax, DWORD[stack_size]
    cmp     eax, 0
    jne     is_stack_empty_false
        mov eax, 1
        mov     esp, ebp
        pop     ebp
        ret 
    is_stack_empty_false:
        mov eax, 0
    mov     esp, ebp
    pop     ebp
    ret 


generate_maze:
    push    ebp
    mov     ebp, esp 
    ;ebp + 12 = y
    ;ebp + 16 = x
    ;ebp - 4 = STEP_SIZE
    sub     esp, 4

    push DWORD[ebp+12]
    push DWORD[ebp+8]
    push 0
    call add_to_stack
    add  esp, 12

    mov  al, BYTE[EMPTY_CHAR]
    push DWORD[ebp+12]
    push DWORD[ebp+8]
    push eax
    call set_pixel
    add  esp, 12

    generate_maze_first_while_top:
    call    is_stack_empty
    cmp     eax, 0
    jne     generate_maze_first_while_bot

        ;ebp - 8 = cx
        ;ebp - 12 = cy
        ;ebp - 16 = dir
        sub     esp, 12
        call    top_of_stack
        mov     DWORD[ebp-8],  eax
        mov     DWORD[ebp-12], ebx
        mov     DWORD[ebp-16], ecx

        ;ebp - 20 = available_dirs
        sub     esp, 4
        mov     DWORD[ebp-20], 0

        push DWORD[ebp-8]
        mov  ebx, DWORD[ebp-12]
        sub  ebx, DWORD[STEP_SIZE]
        push ebx
        mov  al, BYTE[WALL_CHAR]
        push eax
        call is_pixel
        add esp, 12

        cmp eax, 1
        jne generate_maze_second_if
            mov ebx, DWORD[ebp-20]
            or ebx, 0x0001
            mov DWORD[ebp-20],ebx


        generate_maze_second_if:
        push DWORD[ebp-8]
        mov  ebx, DWORD[ebp-12]
        add  ebx, DWORD[STEP_SIZE]
        push ebx
        mov  al, BYTE[WALL_CHAR]
        push eax
        call is_pixel
        add esp, 12

        cmp eax, 1
        jne generate_maze_third_if
            mov ebx, DWORD[ebp-20]
            or ebx, 0x0010
            mov DWORD[ebp-20],ebx


        generate_maze_third_if:
        mov ebx, DWORD[ebp-8]
        sub ebx, DWORD[STEP_SIZE]
        push ebx

        push DWORD[ebp-12]
        mov  al, BYTE[WALL_CHAR]
        push eax
        call is_pixel
        add esp, 12

        cmp eax, 1
        jne generate_maze_fourth_if
            mov ebx, DWORD[ebp-20]
            or ebx, 0x0100
            mov DWORD[ebp-20],ebx

        generate_maze_fourth_if:
        mov ebx, DWORD[ebp-8]
        add ebx, DWORD[STEP_SIZE]
        push ebx

        push DWORD[ebp-12]
        mov  al, BYTE[WALL_CHAR]
        push eax
        call is_pixel
        add esp, 12

        cmp eax, 1
        jne generate_maze_last_if
            mov ebx, DWORD[ebp-20]
            or ebx, 0x1000
            mov DWORD[ebp-20],ebx

        generate_maze_last_if:

        mov eax, DWORD[ebp-20]
        cmp eax, 0x0000
        jne available_dirs_not_zero
            call pop_off_stack
            jmp generate_maze_first_while_top

        available_dirs_not_zero:

        ;change_direction = ebp - 24
        sub esp, 4
        call rand
        mov  esi, 100
        cdq
        idiv  esi
        cmp  edx, 50
        jge  set_change_direction_true
            mov DWORD[ebp-24], 0
            jmp set_change_direction_false
        set_change_direction_true:
            mov DWORD[ebp-24], 1
        set_change_direction_false:
        ;while(1)
        generate_maze_inner_first_while_top:
            call display
            mov ebx, DWORD[ebp-24]
            cmp ebx, 0
            je do_not_change_direction
                ;ebp-28 = found_new_direction
                sub esp, 4
                ;while(!found_new_direction)
                mov DWORD[ebp - 28], 0
                generate_maze_inner_first_inner_first_while_top:
                mov ebx, DWORD[ebp-28]
                cmp ebx, 0
                jne generate_maze_inner_first_inner_first_while_bot

                ;ebp-16 = 1 << (4 * (rand() % 4))  
                call    rand
                mov     esi, 4
                cdq
                idiv     esi
                mov     eax, edx
                mov     esi, 4
                imul     esi
                mov     ebx, 1
                mov     cl, al
                shl     ebx, cl

                mov     DWORD[ebp-16], ebx
                mov     ecx, DWORD[ebp-16]
                and     ecx, DWORD[ebp-20]
                cmp     ebx, ecx
                jne     generate_maze_inner_first_inner_first_while_top 
                    mov DWORD[ebp-28], 1
                    jmp     generate_maze_inner_first_inner_first_while_top
                generate_maze_inner_first_inner_first_while_bot:
                add esp, 4
            do_not_change_direction:
            ;ebp - 28 = dx
            ;ebp - 32 = dy
            sub     esp, 8
            mov    DWORD[ebp-28], 0
            mov    DWORD[ebp-32], 0

            mov ebx,DWORD[ebp-16]
            cmp ebx, 0x0001
            jne not_0x0001
                mov eax, DWORD[STEP_SIZE]
                mov esi, -1
                imul esi
                mov DWORD[ebp-32], eax

            not_0x0001:
            cmp ebx, 0x0010
            jne not_0x0010
                mov eax, DWORD[STEP_SIZE]
                mov DWORD[ebp-32], eax

            not_0x0010:
            cmp ebx, 0x0100
            jne not_0x0100
                mov eax, DWORD[STEP_SIZE]
                mov esi, -1
                imul esi
                mov DWORD[ebp-28], eax

            not_0x0100:
            cmp ebx, 0x0100
            jne not_0x1000
                mov eax, DWORD[STEP_SIZE]
                mov DWORD[ebp-28], eax
            not_0x1000:
                mov    eax, DWORD[ebp-28]
                call    print_int
                call    print_nl
                mov    eax, DWORD[ebp-32]
                call    print_int
                call    print_nl
            ;ebp - 36 = tx
            ;ebp - 40 = ty
            sub     esp, 8
            mov     eax, DWORD[ebp-28]
            add     eax, DWORD[ebp-8]
            mov     DWORD[ebp-36],eax

            mov     eax, DWORD[ebp-32]
            add     eax, DWORD[ebp-12]
            mov     DWORD[ebp-40],eax

            push    DWORD[ebp-36]
            push    DWORD[ebp-40]
            call    in_bounds
            add     esp, 8
            cmp     eax, 0
            je     not_in_bounds_or_in_pixel
                push    DWORD[ebp-36]
                push    DWORD[ebp-40]
                mov     al, BYTE[WALL_CHAR]
                push    eax
                call    is_pixel
                add     esp, 12
                cmp     eax, 0
                je      not_in_bounds_or_in_pixel
                    ;ebp - 44 = s
                    sub esp, 4
                    mov DWORD[ebp - 44],1
                    generate_maze_inner_first_for_top:
                    mov eax, DWORD[ebp-44]
                    cmp eax, DWORD[STEP_SIZE]
                    jg  generate_maze_inner_first_for_bot
                        ;cx + s * dx / STEP_SIZE
                        mov ebx, DWORD[ebp-28]
                        mul ebx
                        mov ecx, DWORD[STEP_SIZE]
                        cdq
                        div ecx
                        add eax, DWORD[ebp-8]
                        push eax

                        ;cy + s * dy / STEP_SIZE
                        mov eax, DWORD[ebp-44]
                        mov ebx, DWORD[ebp-32]
                        mul ebx
                        mov ecx, DWORD[STEP_SIZE]
                        cdq
                        div ecx
                        add eax, DWORD[ebp-12]
                        push eax

                        mov al, BYTE[EMPTY_CHAR]
                        push eax
                        call set_pixel
                        add  esp, 12
                    inc DWORD[ebp-44]
                    jmp generate_maze_inner_first_for_top
                    generate_maze_inner_first_for_bot:
                    push DWORD[ebp - 36]
                    push DWORD[ebp - 40]
                    push DWORD[ebp - 16]
                    call add_to_stack
                    add esp, 12

                    add esp, 4
                    jmp generate_maze_inner_first_while_bot
            not_in_bounds_or_in_pixel:
                ;ebp - 24
                mov DWORD[ebp-24], 1
        add esp, 16
        jmp generate_maze_inner_first_while_top
        generate_maze_inner_first_while_bot:
    add esp, 20
    jmp generate_maze_first_while_top
    generate_maze_first_while_bot:
    add esp, 4
    mov     esp, ebp
    pop     ebp
    ret 