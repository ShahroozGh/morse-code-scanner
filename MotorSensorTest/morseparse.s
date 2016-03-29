# initialize r10, r22, & r23 to 0 before calling this function for the first time; do not overwrite - global
# allocate space in memory for the morse sequence. Initialize r9 to point to this mem addr (and pass it as a param)

# explanation of the (relative) timing convention:
# all element lengths are integer (a) multiples of the dot
# 0x0 Dot  			= x 		
# 0x1 Dash 			= 3x 		a dot/dash is an "element"
# 0xD Element pause 		= x		there must be a break of length (x) between dots/dashes
# 0xE Char pause 		= 3x		go to next character; done with current char
# 0xF Word pause (space) 	= 7x		blank white space; done with current word

# (absolute) timing convention
# WPM = 1.2 * ( 1 / x ); 		1 / x = frequency
# at WPM = 10, x = 0.12 s
# at WPM = 15, x = 0.08 s

# at a sample rate of 100 Hz, there must be ( a * x * 100 ) - 1 consecutive hits to qualify as an element
# for example, at WPM = 15 -> x = 0.08s -> there must be ( 3 * 0.08 * 100 ) - 1 = 23 consecutive hits to qualify as a dash

# AS OF THE FIRST REVISION, QUITE A FEW VALUES ARE HARD-CODED. THIS MAY NOT BE IDEAL AND WILL BE REVISED

# ________________________________________________________________________________________________________________
# LOGIC:

# function takes in a "boolean" value - is the sensor detecting an input above the threshold, or not - in r8
morseParse:

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

# by default, assume WPM = 15 -> x = 0.08 -> x * 100 = 8.  Maybe implement WPM settings based on switches?
# store x * 100 in r9 (or fetch from memory maybe?)
# movi r9, 0x8 - NOT CURRENTLY USED

# mask the LSB (boolean bit) of r8 - referred to as a *this* "sample" from here on
andi r16, r8, 0x1

# use r10 to save whether the *previous* sample was a hit/miss (hit = 1 = above threshold, miss = 0 = below threshold)

# if ( *this* sample == *previous* sample ), jump to increment logic
beq r16, r10, incre		
# else reset r22 & r23, and since the sequence has been broken, check for an element
mov r22, r0
mov r23, r0
br checkElement

# use r22 to keep track of how many consecutive hits, r23 for consecutive misses
incre:
beq r16, r0, increMiss
addi r22, r22, 1		# else increment r22 (hit)
br end

increMiss:			
addi r23, r23, 1

# if the sequence has been broken, check r22 & r23 for an element
checkElement:
movi r20, 55			# r20 = 7x - 1
bge r23, r20, saveWordPause	# if ( more than 55 consecutive misses ), save a "Word pause" to memory

movi r20, 23			# r20 = 3x - 1
bge r23, r20, saveCharPause	# if ( more than 23 consecutive misses ), save a "Char pause" to memory
bge r22, r20, saveDash		# if ( more than 23 consecutive hits ), save a "Dash" to mem

movi r20, 7			# r20 = x - 1
bge r23, r20, saveElemPause	# if ( more than 7 consecutive misses ), save a "Element pause" to memory
bge r22, r20, saveDot		# if ( more than 7 consecutive hits ), save a "Dot" to memory


saveWordPause:
movi r21, 0xF			# store "Word pause" to reg
stb r21, (r9)			# store "Word pause" to memory addr 
increMem			# increment memory pointer (move on to next element)

saveCharPause:
movi r21, 0xE			# store "Char pause" to reg
stb r21, (r9)			# store "Char pause" to memory addr 
increMem			# increment memory pointer (move on to next element)

saveDash:
movi r21, 0x1			# store "Dash" to reg
stb r21, (r9)			# store "Dash" to memory addr 
increMem			# increment memory pointer (move on to next element)

saveElemPause:
movi r21, 0xD			# store "Elem pause" to reg
stb r21, (r9)			# store "Elem pause" to memory addr 
increMem			# increment memory pointer (move on to next element)

saveDot:
movi r21, 0x0			# store "Dot" to reg
stb r21, (r9)			# store "Dot" to memory addr 
increMem			# increment memory pointer (move on to next element)

increMem:
addi r9, r9, 2		# increment memory pointer (move on to next element)

end:
# save *this* sample into r10 (to be used again in next run)
mov r10, r16

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

# go back for more :D
ret
