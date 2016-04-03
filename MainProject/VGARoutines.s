.equ VGA_ADDR, 0x08000000
.equ CHAR_ADDR, 0x09000000

.equ VGA_END_ADDR, 0x0803BE7E
.equ CHAR_END_ADDR, 0x09001DCF

.equ MORSE_START_X, 10
.equ MORSE_START_Y, 10
.equ MORSE_HIGHT, 5
.equ UNIT_WIDTH, 5
.equ DASH_WIDTH, 10



.global draw_encoded_morse
#takes in NOTHING
draw_encoded_morse:

addi sp, sp, -52

#Callee saved registers
stw r16, 0(sp)
stw r17, 4(sp)
stw r18, 8(sp)
stw r19, 12(sp)
stw r20, 16(sp)
stw r21, 20(sp)
stw r22, 24(sp)
stw r23, 28(sp)

stw ra, 32(sp)
stw r4, 36(sp)
stw r5, 40(sp)
stw r6, 44(sp)
stw r7, 48(sp)

#Logic here

	#Pointer to encoded array, Increment this to keep track of where we are in the array
	movia r16, ENCODED_MORSE
	
	#Size of array
	movia r17, ENCODED_MORSE_SIZE
	ldw r17, (r17)
	
	#FINAL LOCATION + 1
	add r17, r17, r16
	
	movui r22, MORSE_START_X
	#movui r23, MORSE_START_Y
	
	#Iterate throuogh array and draw
	
	DRAW_NEXT_SYMBOL:
	
	#If we get to final address+1 stop
	beq r17, r16, FINISH_MORSE_DRAW
	
	#Load Encoded symbol
	ldw r18, (r16)
	
	#Check what to draw
	movui r19, 1
	beq r18, r19, DRAW_DOT
	
	movui r19, 2
	beq r18, r19, DRAW_DASH
	
	movui r19, 3
	beq r18, r19, DRAW_UNIT_SPACE
	
	#Draw dot/dash then unit space
	DRAW_DOT:
		mov r4, r22
		movui r5, MORSE_START_Y
		movui r6, UNIT_WIDTH
		movui r7, MORSE_HIGHT
		call draw_rect_border
		addi r22, r22, 5
		br DRAW_UNIT_SPACE
	DRAW_DASH:
		mov r4, r22
		movui r5, MORSE_START_Y
		movui r6, DASH_WIDTH
		movui r7, MORSE_HIGHT
		call draw_rect_border
		addi r22, r22, 10
		br DRAW_UNIT_SPACE
	
	DRAW_CHAR_SPACE:
		addi r22, r22, 5
		br DRAW_UNIT_SPACE
	
	DRAW_UNIT_SPACE:
		addi r22, r22, 5
		
	#Increment address
	addi r16, r16, 4
	
	br DRAW_NEXT_SYMBOL
	
	FINISH_MORSE_DRAW:
  
#Return registers to how they were before call

ldw r16, 0(sp)
ldw r17, 4(sp)
ldw r18, 8(sp)
ldw r19, 12(sp)
ldw r20, 16(sp)
ldw r21, 20(sp)
ldw r22, 24(sp)
ldw r23, 28(sp)

ldw ra, 32(sp)
ldw r4, 36(sp)
ldw r5, 40(sp)
ldw r6, 44(sp)
ldw r7, 48(sp)

addi sp, sp, 52 #Return stack pointer 

ret


####FILLS_SCREEN BLACK

.global fill_screen
fill_screen:

addi sp, sp, -52

#Callee saved registers
stw r16, 0(sp)
stw r17, 4(sp)
stw r18, 8(sp)
stw r19, 12(sp)
stw r20, 16(sp)
stw r21, 20(sp)
stw r22, 24(sp)
stw r23, 28(sp)

stw ra, 32(sp)
stw r4, 36(sp)#N stored here
stw r5, 40(sp)
stw r6, 44(sp)
stw r7, 48(sp)	

#Logic here

	#load VGA Address
	movia r16, VGA_ADDR
	
	NEXT_PX:
	#set color to BLACK
	movui r17, 0x0000 #black px
	sthio r17, (r16)
	
	#Check if we are at the end address
	movia r17, VGA_END_ADDR
	beq r16, r17, FILL_DONE
	#Go to next address
	addi r16, r16, 2
	
	br NEXT_PX
	
	FILL_DONE:
	
	
  
#Return registers to how they were before call

ldw r16, 0(sp)
ldw r17, 4(sp)
ldw r18, 8(sp)
ldw r19, 12(sp)
ldw r20, 16(sp)
ldw r21, 20(sp)
ldw r22, 24(sp)
ldw r23, 28(sp)

ldw ra, 32(sp)
ldw r4, 36(sp)
ldw r5, 40(sp)
ldw r6, 44(sp)
ldw r7, 48(sp)

addi sp, sp, 52 #Return stack pointer 

ret


.global clear_char_buff
clear_char_buff:

addi sp, sp, -52

#Callee saved registers
stw r16, 0(sp)
stw r17, 4(sp)
stw r18, 8(sp)
stw r19, 12(sp)
stw r20, 16(sp)
stw r21, 20(sp)
stw r22, 24(sp)
stw r23, 28(sp)

stw ra, 32(sp)
stw r4, 36(sp)#N stored here
stw r5, 40(sp)
stw r6, 44(sp)
stw r7, 48(sp)	

#Logic here

	#load VGA Address
	movia r16, CHAR_ADDR
	
	NEXT_CHAR:
	#set color to BLACK
	movi r17, 0x00 #empty char
	stbio r17, (r16)
	
	#Check if we are at the end address
	movia r17, CHAR_END_ADDR
	beq r16, r17, CLEAR_DONE
	#Go to next address
	addi r16, r16, 1
	
	br NEXT_CHAR
	
	CLEAR_DONE:
	
	
  
#Return registers to how they were before call

ldw r16, 0(sp)
ldw r17, 4(sp)
ldw r18, 8(sp)
ldw r19, 12(sp)
ldw r20, 16(sp)
ldw r21, 20(sp)
ldw r22, 24(sp)
ldw r23, 28(sp)

ldw ra, 32(sp)
ldw r4, 36(sp)
ldw r5, 40(sp)
ldw r6, 44(sp)
ldw r7, 48(sp)

addi sp, sp, 52 #Return stack pointer 

ret

#takes in x,y in screen coords and color then draws px there, function takes care of calculating offset
.global draw_px_at_xy
draw_px_at_xy:

addi sp, sp, -52

#Callee saved registers
stw r16, 0(sp)
stw r17, 4(sp)
stw r18, 8(sp)
stw r19, 12(sp)
stw r20, 16(sp)
stw r21, 20(sp)
stw r22, 24(sp)
stw r23, 28(sp)

stw ra, 32(sp)
stw r4, 36(sp)#x parameter
stw r5, 40(sp)#y parameter
stw r6, 44(sp)#color
stw r7, 48(sp)	

#Logic here
	#Offset = 2*x, + 1024*y
	
	#make sure parameters are within bounds
	#(0,0) -> (319, 239)
	
	blt r4, r0, INVALID_PX
	blt r5, r0, INVALID_PX
	
	movia r18, 319
	bgt r4, r18, INVALID_PX
	movia r18, 239
	bgt r5, r18, INVALID_PX
	
	
	#load VGA Address
	movia r16, VGA_ADDR
	
	#calculate offset
	
	muli r18, r4, 2
	muli r19, r5, 1024
	add r19, r19, r18
	
	#r19 is now offset
	#get offset address
	add r16, r16, r19
	

	sthio r6, (r16)
	
	br PX_DONE
	
	#IF INVALID COORDS
	INVALID_PX:
	#DRAW RED TO 00 for debug purposes
	movia r16, VGA_ADDR
	movui r6, 0xF800 
	sthio r6, (r16)
	
	PX_DONE:
	
  
#Return registers to how they were before call

ldw r16, 0(sp)
ldw r17, 4(sp)
ldw r18, 8(sp)
ldw r19, 12(sp)
ldw r20, 16(sp)
ldw r21, 20(sp)
ldw r22, 24(sp)
ldw r23, 28(sp)

ldw ra, 32(sp)
ldw r4, 36(sp)
ldw r5, 40(sp)
ldw r6, 44(sp)
ldw r7, 48(sp)

addi sp, sp, 52 #Return stack pointer 

ret

.global draw_rect
#takes in x,y of top corner of rect and width (x), length (y)
draw_rect:

addi sp, sp, -52

#Callee saved registers
stw r16, 0(sp)
stw r17, 4(sp)
stw r18, 8(sp)
stw r19, 12(sp)
stw r20, 16(sp)
stw r21, 20(sp)
stw r22, 24(sp)
stw r23, 28(sp)

stw ra, 32(sp)
stw r4, 36(sp)#x parameter
stw r5, 40(sp)#y parameter
stw r6, 44(sp)# x width
stw r7, 48(sp)# y length

#Logic here
	#Offset = 2*x, + 1024*y
	#x and y
	mov r17, r4
	mov r18, r5
	
	mov r19, r6
	mov r20, r7
	
	#calc end px x and y
	add r19, r19, r4
	add r20, r20, r5
	
	addi r19, r19, -1
	addi r20, r20, -1
	
	#init x any y counters
	mov r22, r17
	mov r23, r18
	
	movui r16, 0xFF00 #color
	#make sure parameters are within bounds
	#(0,0) -> (319, 239)
	
	ITERATE_THROUGH:
	
		mov r4, r22 #x
		mov r5, r23 #y
		mov r6, r16 #Color
		call draw_px_at_xy
		
		beq r22, r19, X_END 
		#Not end end x coord
		#Increment x then draw again
		addi r22, r22, 1
		br ITERATE_THROUGH
		
		#End of x, reset x, increment y
		X_END:
		mov r22, r17
		br INCR_Y
		
		INCR_Y:
		beq r23, r20, Y_END
		#Not end of y, increment y, redraw
		addi r23, r23, 1
		br ITERATE_THROUGH
		
		#End of y, drawing done
		Y_END:
	
  
#Return registers to how they were before call

ldw r16, 0(sp)
ldw r17, 4(sp)
ldw r18, 8(sp)
ldw r19, 12(sp)
ldw r20, 16(sp)
ldw r21, 20(sp)
ldw r22, 24(sp)
ldw r23, 28(sp)

ldw ra, 32(sp)
ldw r4, 36(sp)
ldw r5, 40(sp)
ldw r6, 44(sp)
ldw r7, 48(sp)

addi sp, sp, 52 #Return stack pointer 

ret

#Draw unfilled rectangle

.global draw_rect_border
#takes in x,y of top corner of rect and width (x), length (y)
draw_rect_border:

addi sp, sp, -52

#Callee saved registers
stw r16, 0(sp)
stw r17, 4(sp)
stw r18, 8(sp)
stw r19, 12(sp)
stw r20, 16(sp)
stw r21, 20(sp)
stw r22, 24(sp)
stw r23, 28(sp)

stw ra, 32(sp)
stw r4, 36(sp)#x parameter
stw r5, 40(sp)#y parameter
stw r6, 44(sp)# x width
stw r7, 48(sp)# y length

#Logic here
	#Offset = 2*x, + 1024*y
	#x and y
	mov r17, r4
	mov r18, r5
	
	mov r19, r6
	mov r20, r7
	
	#calc end px x and y
	add r19, r19, r4
	add r20, r20, r5
	
	addi r19, r19, -1
	addi r20, r20, -1
	
	#init x any y counters
	mov r22, r17
	mov r23, r18
	
	movui r16, 0xFFF0 #color
	#make sure parameters are within bounds
	#(0,0) -> (319, 239)
		
		
		#Top line, y=y, x=x to x=xend
		
		ITERATE_TOP:
		mov r4, r22 #x
		mov r5, r23 #y
		mov r6, r16 #Color
		call draw_px_at_xy
		
		beq r22, r19, ITERATE_LEFT_RESET 
		#Not end end x coord
		#Increment x then draw again
		addi r22, r22, 1
		br ITERATE_TOP
		
		ITERATE_LEFT_RESET:
		mov r22, r17 # X to beginning
		mov r23, r18 # Y to beginning
		
		ITERATE_LEFT:
		mov r4, r22 #x
		mov r5, r23 #y
		mov r6, r16 #Color
		call draw_px_at_xy
		
		beq r23, r20, ITERATE_BOTTOM_RESET
		#Not end end y coord
		#Increment y then draw again
		addi r23, r23, 1
		br ITERATE_LEFT
		
		ITERATE_BOTTOM_RESET:
		mov r22, r17 # X to beginning
		mov r23, r20 # Y to End
		
		ITERATE_BOTTOM:
		mov r4, r22 #x
		mov r5, r23 #y
		mov r6, r16 #Color
		call draw_px_at_xy
		
		beq r22, r19, ITERATE_RIGHT_RESET
		#Not end end x coord
		#Increment x then draw again
		addi r22, r22, 1
		br ITERATE_BOTTOM
		
		ITERATE_RIGHT_RESET:
		mov r22, r19 # X to End
		mov r23, r18 # Y to Beginning
		
		ITERATE_RIGHT:
		mov r4, r22 #x
		mov r5, r23 #y
		mov r6, r16 #Color
		call draw_px_at_xy
		
		beq r23, r20, DONE_BORDER
		#Not end end x coord
		#Increment x then draw again
		addi r23, r23, 1
		br ITERATE_RIGHT
		
		
		DONE_BORDER:
		
	
  
#Return registers to how they were before call

ldw r16, 0(sp)
ldw r17, 4(sp)
ldw r18, 8(sp)
ldw r19, 12(sp)
ldw r20, 16(sp)
ldw r21, 20(sp)
ldw r22, 24(sp)
ldw r23, 28(sp)

ldw ra, 32(sp)
ldw r4, 36(sp)
ldw r5, 40(sp)
ldw r6, 44(sp)
ldw r7, 48(sp)

addi sp, sp, 52 #Return stack pointer 

ret


