IDEAL
MODEL small
STACK 100h
P286

include 'graphics.inc'
include 'engine.inc'
include 'bmp.inc'
include 'io.inc'

DATASEG

; Error Messages

byUser@error	db	'Program closed by user.$'
blank@error		db	'Woops! nothing here.$'

; Directories

root@wd			db	'../', 0
pieces@wd		db	'assets', 0

; Selection

sourcePos@sel	dd	0
destPos@sel		dd	0
step@sel		dw	0

; Win Messages

white@win		db 'Game ended. White won!$'
black@win		db 'Game ended. Black won!$'



CODESEG

START:
	mov ax, @data
	mov ds, ax

	mov ah, 3Bh ; Set Working Dir
	mov dx, offset pieces@wd
	int 21h

	call initBoard@engine
	call initGraph@graphics

	mov al, 14h
	call cleanScreen@graphics
	call drawBoard@graphics

	mov di, 7
	mov si, 7
	mov al, [markColor@graphics]
	call markCube@graphics

	mov [markerCol@io], di
	mov [markerRow@io], si

	call printScore@graphics

	

	
	game@start:

		
			
		mov [step@sel], 0
		cmp [turn@engine], 0
		jg black@game



		white@game:
			getSource@white:
				call getData@io

				push si
				push di
				inc [step@sel]

				push offset board@engine				;pop of this value is inside getOffset
				call getOffset@engine					;getOffset uopdate bx with offset board + si * 8 + di
				mov [sourceAddr@engine], bx				

				call validateSource@engine
				jc shortJmp@game


			getDest@white:
				call getData@io

				push si
				push di
				inc [step@sel]

				push offset board@engine			;pop of this value is inside getOffset
				call getOffset@engine				;getOffset uopdate bx with offset board + si * 8 + di
				mov [destAddr@engine], bx

				call validateDest@engine
				jc shortJmp@game

				mov si, [sourceAddr@engine]
				mov di, [destAddr@engine]

				call validateMove@engine
				jc shortJmp@game
				jmp continue@game

		shortJmp@game:
			jmp invalid@game
		
		greedyJmp@game:
			jmp greedyChack@black

		black@game:

			cmp [greedyIndicator@engine], 0		;Starting with greedy Algorithm 
			je greedy@black
			jmp getSource@black

			greedy@black:
				mov [BestScoreEver@engine], 0  ;initialize the BestScoreEver@engine 
				mov ax, -1
				mov [sorPTR@engine], ax

				greedyLoop@greedy:

				mov ax, [sorPTR@engine]			;Restore ax for loop
				inc ax
				cmp ax, 64
				je greedyJmp@game
				mov [sorPTR@engine], ax			;Store ax in destPTR so we can use ax freely
				

				mov di, ax					;di = destPTR / 8
				and di, 7d

				shr ax, 3					;si = destPTR % 8
				and ax, 7d
				mov si, ax					
			

				mov [xgsor@engine], si				;this is needed for debug only
				mov [ygsor@engine], di				;this is needed for debug only
			

				push offset board@engine		;pop of this value is inside getOffset
				call getOffset@engine			;getOffset uopdate bx with offset board + si * 8 + di
				mov [sourceAddr@engine], bx

				call validateSource@engine
				jc greedyLoop@greedy

				dest@greedyLoop:
					mov ax, -1
					mov [destPTR@engine], ax

					greedyLoop@dest:

						mov ax, [destPTR@engine]			;Restore ax for loop
						inc ax
						cmp ax, 64
						je greedyLoop@greedy
						mov [destPTR@engine], ax			;Store ax in destPTR so we can use ax freely
				

						mov di, ax					;di = destPTR % 8
						and di, 7d

						shr ax, 3					;si = destPTR % 8
						and ax, 7d
						mov si, ax					
			

						mov [xgDst@engine], si				;this is needed for debug only
						mov [ygDst@engine], di				;this is needed for debug only
			

						push offset board@engine		;pop of this value is inside getOffset
						call getOffset@engine			;getOffset uopdate bx with offset board + si * 8 + di
						mov [destAddr@engine], bx

						call validateDest@engine
						jc greedyLoop@dest

						mov si, [sourceAddr@engine]
						mov di, [destAddr@engine]

						call validateMove@engine
						jc greedyLoop@dest

						mov bx, [destAddr@engine]
						mov ax, 0
						mov al, [byte bx]
						neg al
						cmp [BestScoreEver@engine], ax
						jnl greedyLoop@dest
						mov [BestScoreEver@engine], ax

						mov ax, [xgsor@engine]
						mov [xsorbest@engine], ax
						mov ax, [ygsor@engine]
						mov [ysorbest@engine], ax 
						mov ax, [xgDst@engine]
						mov [xDstbest@engine], ax 
						mov ax, [ygDst@engine]
						mov [yDstbest@engine], ax

						
						mov ax, [sourceAddr@engine]
						mov [bestsourceAddr@engine], ax
						mov ax, [destAddr@engine]
						mov [bestdestAddr@engine], ax

						jmp greedyLoop@dest

			greedyChack@black:
				mov [greedyIndicator@engine], 1     ;the greedyIndicator@engine is used to check if i was in greedy already
				cmp [BestScoreEver@engine], 0
				je shortJmp2@game
				mov si, [xsorbest@engine]
				mov di, [ysorbest@engine]
				push si
				push di
				inc [step@sel]
				mov si, [xDstbest@engine]
				mov di, [yDstbest@engine]
				push si
				push di
				inc [step@sel]
				mov si, [bestsourceAddr@engine]
				mov di, [bestdestAddr@engine]
				jmp continue@game

		shortJmp2@game:
			jmp invalid@game


			getSource@black:
				mov ax, 40h						
				mov es, ax
				mov ax, [es:06Ch] 
				xor ah, ah
				and al, 00000111b
				mov si, ax							;si = Random number from clock (3 bits)

				mov ax, 40h
				mov es, ax
				mov ax, [es:06Ch]
				shr ax, 3d
				xor ah, ah
				and al, 00000111b
				mov di, ax							;di = Random number from clock (3 bits)

				
				;push ax
				;mov ah, 00
				;int 16h
				;pop ax

				;1 second delay
				push cx
				push dx
				push ax
				mov cx, 0fh
				mov dx, 4240h
				mov ah, 86h
				int 15h
				pop ax
				pop dx
				pop cx


				push si
				push di
				inc [step@sel]

				push offset board@engine		;pop of this value is inside getOffset
				call getOffset@engine			;getOffset uopdate bx with offset board + si * 8 + di
				mov [sourceAddr@engine], bx

				call validateSource@engine
				jc shortJmp2@game


			getDest@black:
				
				
				mov ax, -1
				mov [destPTR@engine], ax

				destLoop@getDest:

				mov ax, [destPTR@engine]			;Restore ax for loop
				inc ax
				cmp ax, 64
				je shortJmp2@game
				mov [destPTR@engine], ax			;Store ax in destPTR so we can use ax freely
				

				mov di, ax					;di = destPTR % 8
				and di, 7d

				shr ax, 3					;si = destPTR % 8
				and ax, 7d
				mov si, ax					
			

				mov [xDst@engine], si				;this is needed for debug only
				mov [yDst@engine], di				;this is needed for debug only
			

				push offset board@engine		;pop of this value is inside getOffset
				call getOffset@engine			;getOffset uopdate bx with offset board + si * 8 + di
				mov [destAddr@engine], bx

				call validateDest@engine
				jc destLoop@getDest

				mov si, [sourceAddr@engine]
				mov di, [destAddr@engine]

				call validateMove@engine
				jc destLoop@getDest

				 
				mov si, [xDst@engine]
				mov di, [yDst@engine]
				push si
				push di

				mov si, [sourceAddr@engine]
				mov di, [destAddr@engine]

				inc [step@sel]
				jmp continue@game	


		continue@game:
		mov [greedyIndicator@engine], 0

		

		cmp [byte di], 6
		je white_won@game

		cmp [byte di], -6
		je black_won@game

		call Rating@engine
		call printScore@graphics

		call move@engine

		mov cx, [step@sel]
		updateBoard@game:
			pop di
			pop si

			push cx

			call getColor@graphics
			call drawCube@graphics

			pop cx
			loop updateBoard@game


		updateMark@game:
			mov di, [markerCol@io]
			mov si, [markerRow@io]

			mov al, [markColor@graphics]
			call markCube@graphics
		
		neg [turn@engine]
		
		jmp game@start

		invalid@game:
			add sp, [step@sel]
			add sp, [step@sel]

			mov di, [markerCol@io]
			mov si, [markerRow@io]

			mov al, 0Ch
			call markCube@graphics

			

			jmp game@start

		white_won@game:
			mov dx, offset white@win
			jmp exit_msg

		black_won@game:
			mov dx, offset black@win
			jmp exit_msg

	EXIT:
		mov dx, offset blank@error

	exit_msg:
		; Flush io buffer
		mov ah, 0Ch
		int 21h

		; Text Mode
		mov ax, 2h
		int 10h

		; Error Msg
		mov ah, 9h
		int 21h

		; Restore WD
		mov ah, 3Bh
		mov dx, offset root@wd
		int 21h

		; Terminate Program
		mov ax, 4c00h
		int 21h

END START