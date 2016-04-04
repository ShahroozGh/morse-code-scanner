
.data #Starts at 200
#Stored Encoded morse code
ENCODED_MORSE:
.word 1
.word 3
.word 2
.word 1
.word 2
.word 1



DECODED_TEXT:
.skip 400  #400 bytes for encoded text


ENCODED_MORSE_SIZE:
.word 24

DECODED_TEXT_SIZE:
.word 0


.text

.global main
main:
	
	
	movia  sp, 0x03FFFFFC			#Init stack pointer Note: 0x03FFFFFF is the last address for the 64MB SDRAM, Use 0x03FFFFFC so that data is aligned
	call decodeMorse
	
LOOP_FOREVER:
    br LOOP_FOREVER                   # Loop forever.

	
	

#Decode and store morse code
decodeMorse:

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
stw r4, 36(sp)#Measured time
stw r5, 40(sp)
stw r6, 44(sp)
stw r7, 48(sp)	

#Logic here
	movia r16, ENCODED_MORSE #To be Incremented, dont overwrite
	movia r17, ENCODED_MORSE_SIZE
	ldw r17, (r17)
	
	#Last address to check + 1, Dont overwrite r17 anymore
	add r17, r17, r16
	
	NEXT_LETTER:
	
	#Check if we have reached the end of the array
	bge r16, r17, DONE_DECODING_ARRAY
	
	#Holds sequence to decode to a char
	mov r22, r0
		CHAR_START:
			
			
			#Get dot/dash/end letter
			ldw r18, (r16)
			
			#check if letter space OR End of array
			movia r19, 3
			beq r18, r19, CHAR_END
			
			#Check if we have reached the end of the array
			beq r16, r17, CHAR_END
			
			
			#If not end
			#Shift sequence holder left and or with dot/dash
			#This is to keep track of the letter's sequence
			slli r22, r22, 4
			or r22, r18, r22
			
			#Increment pointer
			addi r16, r16, 4
			
			
		br CHAR_START	
	
	
	#Char end reached, convery letter to ascii
	CHAR_END:
	
	mov r4, r22
	call morseToAscii
	
	#Store it to Array
	movia r19, DECODED_TEXT
	movia r20, DECODED_TEXT_SIZE
	ldw r20, (r20)
	#Move pointer to top
	add r20, r20, r19
	#Store ascii
	stw r2, (r20)
	
	#Increase size
	movia r20, DECODED_TEXT_SIZE
	ldw r21, (r20)
	addi r21, r21, 4
	
	stw r21, (r20)
	
	
	#Do Next letter
	addi r16, r16, 4
	br NEXT_LETTER
	
	
	DONE_DECODING_ARRAY:
	
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


#Takes in morse letter and returns ascii char
morseToAscii:

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
stw r4, 36(sp)#Measured time
stw r5, 40(sp)
stw r6, 44(sp)
stw r7, 48(sp)	

#Logic here


movui r16, 0x12
beq r4, r16, RETURN_A

movui r16, 0x2111
beq r4, r16, RETURN_B

movui r16, 0x2121
beq r4, r16, RETURN_C

movui r16, 0x211
beq r4, r16, RETURN_D

movui r16, 0x1
beq r4, r16, RETURN_E

movui r16, 0x1121
beq r4, r16, RETURN_F
/*
movui r16, 0x221
beq r4, r16, RETURN_G

movui r16, 0x1111
beq r4, r16, RETURN_H

movui r16, 0x11
beq r4, r16, RETURN_I

movui r16, 0x12
beq r4, r16, RETURN_J

movui r16, 0x212
beq r4, r16, RETURN_K

movui r16, 0x1211
beq r4, r16, RETURN_L

movui r16, 0x22
beq r4, r16, RETURN_M

movui r16, 0x21
beq r4, r16, RETURN_N

movui r16, 0x222
beq r4, r16, RETURN_O

movui r16, 0x1221
beq r4, r16, RETURN_P

movui r16, 0x2212
beq r4, r16, RETURN_Q

movui r16, 0x121
beq r4, r16, RETURN_R

movui r16, 0x111
beq r4, r16, RETURN_S
*/
movui r2, 0x0
br RETURN_ASCII

RETURN_A:
movui r2, 0x41
br RETURN_ASCII

RETURN_B:
movui r2, 0x42
br RETURN_ASCII

RETURN_C:
movui r2, 0x43
br RETURN_ASCII

RETURN_D:
movui r2, 0x44
br RETURN_ASCII

RETURN_E:
movui r2, 0x45
br RETURN_ASCII

RETURN_F:
movui r2, 0x46
br RETURN_ASCII


RETURN_ASCII:
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

