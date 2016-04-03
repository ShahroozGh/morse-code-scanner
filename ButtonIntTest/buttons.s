.equ LEDR, 0xFF200000
.equ ADDR_PUSHBUTTONS, 0xFF200050
.equ IRQ_PUSHBUTTONS, 0x02

#NOTE: r2 and r3 are used as return address's for functions
#dont use them

#Data, Global vars for speed and sensors
.data
led:    
.word 0


#Inturrupt code
.section .exceptions, "ax"
BUTTON_ISR:
	rdctl et, ipending #check ipending for timer interrupt
	andi et, et, 0x02 
	srli et, et, 0x01
	#if irq1 != 1 not button int
	
	beq et, r0, exit #if not zero timer has been called
	
	#Check which button pressed
	
	movia et, ADDR_PUSHBUTTONS
	ldw r2, 12(et)
	andi r2, r2, 0x02
	srli r2, r2, 1
	
	#if 0 then not key 1
	beq r2, r0, CONT 
	
	movia r2, led
	ldw r3, (r2)
	
	beq r3, r0, TURN_ON
	
	#turn led off	
	movia et,LEDR
	movi  r3,0x00
	stwio r3,0(et)

	movia r3, 0
	movia r2, led
	stw r3, (r2)
	br CONT
	
	TURN_ON:
	
	#turn led on	
	movia et,LEDR
	movi  r3,0xFF
	stwio r3,0(et)

	movia r3, 1
	movia r2, led
	stw r3, (r2)
	
	CONT:
		
	
	#Clear edge reg
	movia et,ADDR_PUSHBUTTONS
	movi  r3,-1
	stwio r3, 12(et)

	br exit #Nothing has been called

exit: subi ea, ea, 4
	eret
	
.text

.global main
main:

movia  sp, 0x03FFFFFC			#Init stack pointer Note: 0x03FFFFFF is the last address for the 64MB SDRAM, Use 0x03FFFFFC so that data is aligned
							#so we can init the stack pointer here as the stack will then grow the opposite direction towards addr 0
	
	#Clear edge reg
	movia r2,ADDR_PUSHBUTTONS
	movi  r3,-1
	stwio r3, 12(r2)
	
	movia r2,ADDR_PUSHBUTTONS
	movia r3,0xe
	stwio r3,8(r2)  # Enable interrupts on push buttons 1,2, and 3 

	movia r2,IRQ_PUSHBUTTONS
	wrctl ienable,r2   # Enable bit 5 - button interrupt on Processor 

	movia r2,1
	wrctl ctl0,r2   # Enable global Interrupts on Processor 
	
	#Reset LEDS
	movia r2,LEDR
	movi  r3,0x00
	stwio r3,0(r2)        # Write to LEDs 		
	
LOOP_FOREVER:
    br LOOP_FOREVER                   # Loop forever.

	