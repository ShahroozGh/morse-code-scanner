.equ JP1_ADDR, 0xFF200060
.equ TIMER_ADDR, 0xFF202000
.equ TIMER_ADDR_2, 0xFF202020
.equ LEDR, 0xFF200000
.equ ADDR_PUSHBUTTONS, 0xFF200050
.equ IRQ_PUSHBUTTONS, 0x02
.equ READ_TIME, 1000000000#0x7FFFFFFF #10 seconds
.equ THRESH, 0x07
.equ DELAY, 20
.equ DASH_LENGTH_THRESH, 0x00FFFFFF # 0x02500000
.equ LETTER_BREAK_THRESH,0x00AFFFFF #0x01800000 #0x01000000
.equ SPACE_THRESH, 0x03000000

.data #Starts at 200
#Stored Encoded morse code
.global ENCODED_MORSE
ENCODED_MORSE:
.skip 400 #400 bytes reserved for 100 words

DECODED_TEXT:
.skip 400  #400 bytes for encoded text


DOT_LENGTH:
.word 0

CURRENT_COLOR:
.word 0

PREV_COLOR:
.word 1

BLACK_START_TIME:
.word 0

BLACK_END_TIME:
.word 0xFFFFFFFF

DELAY_BUFFER:
.word 0

.global ENCODED_MORSE_SIZE
ENCODED_MORSE_SIZE:
.word 0

SCAN_RUNNING: #0 For stop, 1 means continue scan, 2 means start decoding
.word 0


.section .exceptions, "ax"

#Save some regs on the stack so we can use them here without clobbering
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

BUTTON_ISR:
	rdctl et, ipending #check ipending for timer interrupt
	andi et, et, 0x02 
	srli et, et, 0x01
	#if irq1 != 1 not button int
	
	beq et, r0, exit_interrupt #if not zero button int has been called
	
	#Check which button pressed
	
	movia et, ADDR_PUSHBUTTONS
	ldw r16, 12(et)
	andi r16, r16, 0x02
	srli r16, r16, 1
	
	#if 0 then not key 1 being pressed
	beq r16, r0, ACK_INT 
	
	#Check if a scan is running
	movia r16, SCAN_RUNNING
	ldw r17, (r16)
	
	#If not running we want to start it
	beq r17, r0, TURN_ON
	
	#turn led Off	
	movia et,LEDR
	movi  r17,0x00
	stwio r17,0(et)
	
	#Set scan running to off
	movia r17, 0
	movia r16, SCAN_RUNNING
	stw r17, (r16)
	br ACK_INT
	
	TURN_ON:
	
	#turn led on	
	movia et,LEDR
	movi  r17,0xFF
	stwio r17,0(et)
	
	#Set scan running to on
	movia r17, 1
	movia r16, SCAN_RUNNING
	stw r17, (r16)
	
	ACK_INT:
		
	
	#Clear edge reg
	movia et,ADDR_PUSHBUTTONS
	movi  r16,-1
	stwio r16, 12(et)

	br exit_interrupt #Nothing has been called







  
#Return registers to how they were before call
exit_interrupt:

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

subi ea, ea, 4
	eret


.text

.global main
main:
	
	
	movia  sp, 0x03FFFFFC			#Init stack pointer Note: 0x03FFFFFF is the last address for the 64MB SDRAM, Use 0x03FFFFFC so that data is aligned
									#so we can init the stack pointer here as the stack will then grow the opposite direction towards addr 0 
	movia  r16, JP1_ADDR 
	movia  r17, 0x07f557ff        	#Set direction for all motors to output 0b0000 0111 1111 0101 0101 0111 1111 1111
	stwio  r17, 4(r16)
	
	#Init motors and sensors to off
    movia r5, 0xFFFFFFFF
	stwio r5, (r16)
	
	
	#Init LEDS and button interrupts
	#Clear edge reg
	movia r17,ADDR_PUSHBUTTONS
	movi  r18,-1
	stwio r18, 12(r17)
	
	movia r17,ADDR_PUSHBUTTONS
	movia r18,0xe
	stwio r18,8(r17)  # Enable interrupts on push buttons 1,2, and 3 

	movia r17,IRQ_PUSHBUTTONS
	wrctl ienable,r17   # Enable bit 5 - button interrupt on Processor 

	movia r17,1
	wrctl ctl0,r17   # Enable global Interrupts on Processor 
	
	#Reset LEDS
	movia r17,LEDR
	movi  r18,0x00
	stwio r18,0(r17)        # Write to LEDs 		
	
	
	WAIT_TO_START:
	#Wait for button interrupt to start
	movia r17, SCAN_RUNNING
	ldw r18, (r17)
	
	beq r18, r0, WAIT_TO_START
	
	#Reset timer
	
	#Start motor timer, When this timer ends we stop reading 
	movia r4, READ_TIME
	call timer2start
	
	#Do not overwrite r17 during polling
	movia  r17, 0x07f557ff  
  #Sensor read
POLL:
 sensor_validity:
	#Get bin code for enable sen0 and keep motor on r17 has prev motor on
	movia  r19, 0xfffffbff 			#Enambe sen0 sen0 = bit 10 b = 1011
	and r19, r19, r17 				#Also keep motor on
 
	stwio  r19, 0(r16)
	ldwio  r21,  0(r16)           	# checking for valid data sensor 
	srli   r21,  r21,11           	# bit 11 is valid bit for sensor        
	andi   r21,  r21,0x1			#mask the first bit
	bne    r0,  r21, sensor_validity# checking if is valid, if not loop back
 valid:
 
	ldwio  r18, 0(r16)         		# read sensor3 value (into r18) 
	srli   r18, r18, 27       		# shift to the right by 27 bits so that 4-bit sensor value is in lower 4 bits 
	andi   r18, r18, 0x0f			#Mask lower 4 bits, r18 now has sensor value
   
   #r18 now has sensor data

   #0 is full light, F no light
	
   MOTOR_MOVE:
   	movia	 r17, 0xfffffffc        # motor0 enabled (bit0=0), direction set to forward (bit1=0) c = 1100 
	stwio	 r17, 0(r16)	
	
	#PWM
	#movia r4, 196666			#Set up parameter N cycles
	movia r4, 60000
	call delayTimer					#Call delay function to wait
	
	movia	 r17, 0xfffffffd        # motor0 disabled (bit0=1), direction set to forward (bit1=0) d = 1101 
	stwio	 r17, 0(r16)
	
	movia r4, 400000				#Set up parameter N cycles
	call delayTimer					#Call delay function to wait
	
	##Sensor value and time to decoder?
	##Use interrupt instead?
	##If value goes above threshold (White -> black) take time snapshot, store in STARTTIME
	##	USE ENDTIME - STARTTIME to determine space or next letter (Dont to this on first loop (No endtime))
	##If value goes below thrshold (black->White) take time snapshot, store in ENDTIME
	##	Use STARTTIME - ENDTIME to determine dot or dash, store?
	
	#if sensor > thresh 
	##	Snapshot->STARTIME
	##  do deltaT = ENDTIME - STARTTIME
	##if 
	
	#movi r5, 0x6
	#bgt r18, r5, BLACK
	#br WHITE:
	
	/* BLACK:
	movui r4, 1
	movui r5, ENCODED_MORSE
	call morseParse
	br POLL_TIMER_2
	
	WHITE:
	movui r4, 0
	movui r5, ENCODED_MORSE
	call morseParse */
	
	
	
	#get a snapshot of the time
	call read_timer2_value
	mov r3, r2
	#Dont check sensor while DELAY is active, this is activated when going from one color to another
	#and doesnt sense again till we are away from edge
	movia r8, DELAY_BUFFER
	ldw r9, (r8)
	
	bne r9, r0, DELAY_CHECK
	
	#if sensor > thresh => black
	movui r3, THRESH
	bgt r18, r3, IS_BLACK
	br IS_WHITE:
	
	IS_BLACK:
		#br READ_COMPLETE
		movia r9, PREV_COLOR
		ldw r8, (r9)
		#If prev is white, there was a change, else do nothing
		movui r9, 1
		beq r8, r9, WHITE_TO_BLACK
		br POLL_TIMER_2 
		
		
		WHITE_TO_BLACK: #Dont set prev color to black right away, need a buffer
		#Start delay buffer
		movui r9, 1
		movia r8, DELAY_BUFFER
		stw r9, (r8)
		
		
		#Set Prev to Black
		movui r8, 0
		movia r9, PREV_COLOR
		stw r8, (r9)
		
		#Store start time
		call read_timer2_value
		movia r9, BLACK_START_TIME
		stw r2, (r9)
		
		#Store NOTHING/LETTER BREAK/SPACE, if not on first black hit
		call storeWhitespace
		
		br POLL_TIMER_2
	
	
	IS_WHITE:
		#br READ_COMPLETE
		movia r9, PREV_COLOR
		ldw r8, (r9)
		#If prev is Black, there was a change, else do nothing
		movui r9, 0
		beq r8, r9, BLACK_TO_WHITE
		br POLL_TIMER_2 
			
		BLACK_TO_WHITE: #Need to store char now
		#Start delay buffer
		movui r9, 1
		movia r8, DELAY_BUFFER
		stw r9, (r8)
		
		#Set Prev to WHITE	
		movui r8, 1
		movia r9, PREV_COLOR
		stw r8, (r9)
		
		call read_timer2_value
		movia r9, BLACK_END_TIME
		stw r2, (r9)
		#Store DOT/DASH to mem
		
		call storeDotOrDash
		
		br POLL_TIMER_2
		#br READ_COMPLETE #Stop
	
	
	#---------------------------------
	#If delay buffer > 0
		#delay buffer ++
		#Check if delay buffer is max
		#If so set to zero
	DELAY_CHECK:
	movia r8, DELAY_BUFFER
	ldw r9, (r8)
	
	#If non zero increment
	bne r9, r0, INCREMENT_BUFF:
	br POLL_TIMER_2
	
	INCREMENT_BUFF:
	addi r9, r9, 1
	#Chack if we should reset
	movui r10, DELAY
	bgt r9, r10, RESET_DELAY
	br STORE_DELAY
	
	RESET_DELAY:
	mov r9, r0
	
	STORE_DELAY:
	stw r9, (r8)
	#---------------------------------
	
	
	
	
	##Check timer 2 to see if we should stop moving
	POLL_TIMER_2:
	movia r15, TIMER_ADDR_2
	ldwio r19, (r15)				#Get time out bit (bit1 first address in timer)
	andi r19, r19, 1				#Mask out first bit
	
	bne r19, r0, READ_COMPLETE		#Check if timer is not 0 ( TO = 1), this means timeout and we can finish reading
	
	
	#Check if SCAN state is still 1, Other wise stop the scan
	CHECK_SCAN_STATE:
	movia r15, SCAN_RUNNING
	ldw r15, (r15)
	beq r15, r0, ONE_LINE_DONE
	
	#Not done, continue moving motor and checking sensor
	br POLL
	
	
	#Read One Line, need to add a char space to memory
	ONE_LINE_DONE:
	##Turn motor off
	movia	 r19, 0xfffffffd        # motor0 disabled (bit0=1), direction set to forward (bit1=0) d = 1101 
	stwio	 r19, 0(r16)
	
	#pointer to morse array
	movia r15, ENCODED_MORSE
	#size of array
	movia r17, ENCODED_MORSE_SIZE
	ldw r17, (r17)
	#Get location of top of array
	add r15, r17, r15
	
	#Store white space
	movui r18, 3
	stw r18, (r15)

	#incr size
	addi r17, r17, 4
	movia r15, ENCODED_MORSE_SIZE
	stw r17, (r15)
	#Reset Start and end times, other state globals
	call resetGlobals
	
	
	#Go back to start loop to wait for start signal
	br WAIT_TO_START
	
	
	READ_COMPLETE:
	##Turn motor off
	movia	 r19, 0xfffffffd        # motor0 disabled (bit0=1), direction set to forward (bit1=0) d = 1101 
	stwio	 r19, 0(r16)
	
	#Start Decoding
	
	#Start Drawing
	#Reset screen to black
	call fill_screen
	
	#Draw morse
	call draw_encoded_morse
	
	#Draw Decoded text
	
LOOP_FOREVER:
    br LOOP_FOREVER                   # Loop forever.

	
#Reset globals needed for another line read
resetGlobals:

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

	movia r16, PREV_COLOR
	movui r17, 1
	stw r17, (r16)
	
	movia r16, BLACK_START_TIME
	movui r17, 0
	stw r17, (r16)
	
	movia r16, BLACK_END_TIME
	movia r17, 0xFFFFFFFF
	stw r17, (r16)
	
	movia r16, DELAY_BUFFER
	movui r17, 0
	stw r17, (r16)
	

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
	
#WHITESPACE DETECT DETECT AND STORE FUNCTION
storeWhitespace:

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

	#Load Start and end time
	movia r16, BLACK_END_TIME
	ldw r17, (r16)
	
	#If BLACK_END_TIME is 0xFFFFFFFF it means it has not been set yet
	#No whitespace to measure
	movi r16, 0xFFFFFFFF
	beq r17, r16, NOTHING_DONE
	
	movia r16, BLACK_START_TIME
	ldw r18, (r16)
	
	#Get time of black
	sub r18, r17, r18
	
	movia r16, LETTER_BREAK_THRESH
	
	bgt r18, r16, STORE_CHAR_SPACE
	br NOTHING_DONE
	
	STORE_CHAR_SPACE:
		#pointer to morse array
		movia r16, ENCODED_MORSE
		#size of array
		movia r17, ENCODED_MORSE_SIZE
		ldw r17, (r17)
		#Get location of top of array
		add r16, r17, r16
		
		#Store white space
		movui r18, 3
		stw r18, (r16)
		br INCR_ENC_SIZE_W
		
	
		
	INCR_ENC_SIZE_W:
		addi r17, r17, 4
		movia r16, ENCODED_MORSE_SIZE
		stw r17, (r16)
	
	NOTHING_DONE:
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
	
	
#DOT/DASH DETECT AND STORE FUNCTION
storeDotOrDash:

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

	#Load Start and end time
	movia r16, BLACK_END_TIME
	ldw r17, (r16)
	
	movia r16, BLACK_START_TIME
	ldw r18, (r16)
	
	#Get time of black
	sub r18, r18, r17
	
	movia r16, DASH_LENGTH_THRESH
	
	bgt r18, r16, STORE_DASH
	br STORE_DOT
	
	STORE_DASH:
		#pointer to morse array
		movia r16, ENCODED_MORSE
		#size of array
		movia r17, ENCODED_MORSE_SIZE
		ldw r17, (r17)
		#Get location of top of array
		add r16, r17, r16
		
		#Store Dash
		movui r18, 2
		stw r18, (r16)
		br INCR_ENC_SIZE
		
	STORE_DOT:
		#pointer to morse array
		movia r16, ENCODED_MORSE
		#pointer to size of array
		movia r17, ENCODED_MORSE_SIZE
		ldw r17, (r17)
		#Get location of top of array
		add r16, r17, r16
		
		#Store DOT
		movui r18, 1
		stw r18, (r16)
		br INCR_ENC_SIZE
		
	INCR_ENC_SIZE:
		addi r17, r17, 4
		movia r16, ENCODED_MORSE_SIZE
		stw r17, (r16)
	
	
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

####TIMER FUNCTION

delayTimer:

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


#Wait
#Set up and start timer
	
	movia r16, TIMER_ADDR         	#Store timer address in reg
	
	movia r20, 0  					#Reset T.O bit
	stwio r20, (r16)
	
	add r17, r0, r4					#Get paramater for N timer cycles
	stwio r17, 8(r16)             	# Set the period to be 196666 clock cycles (LOW BITS)
	srli r17, r17, 16				#Get upper 16 bits to lower
	stwio r17, 12(r16)				#Set period (HIGH BITS)

	movui r17, 4					# 4 = b0100 => stop(0), start (1), CONT (0), ITO(0)
	stwio r17, 4(r16)               # Start timer, no cont, no interrupts

POLL_TIMER:
	ldwio r19, (r16)				#Get time out bit (bit1 first address in timer)
	andi r19, r19, 1				#Mask out first bit
	
	beq r19, r0, POLL_TIMER		#Check if timer is 0 ( TO = 1), if not continue checking
  
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



####second timer function, uses timer 2
##Can set this up with an interrupt
##calling this will start the timer
timer2start:

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


#Wait
#Set up and start timer
	
	movia r16, TIMER_ADDR_2         	#Store timer address in reg
	
	movia r20, 0  					#Reset T.O bit
	stwio r20, (r16)
	
	add r17, r0, r4					#Get paramater for N timer cycles
	stwio r17, 8(r16)             	# Set the period to be 196666 clock cycles (LOW BITS)
	srli r17, r17, 16				#Get upper 16 bits to lower
	stwio r17, 12(r16)				#Set period (HIGH BITS)

	movui r17, 4					# 4 = b0100 => stop(0), start (1), CONT (0), ITO(0)
	stwio r17, 4(r16)               # Start timer, no cont, no interrupts


  
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

#Timer value returned in r2
read_timer2_value:
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


#Wait
	
	movia r16, TIMER_ADDR_2         	#Store timer address in reg
	
	
	stwio r0, 16(r16) #Trigger snapshot
	ldwio r17, 16(r16) # Read snapshot bits 0-15
	ldwio r18, 20(r16) # Read bits 16-31
	slli r18, r18, 16
	or r2, r18, r17 #combine upper and lower bits
	
  
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


    
