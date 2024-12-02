# Weekday Transportation 
# This module calculates the weekday transportation emissions 

.data
# Prompts
main_question: .asciiz "\nDo you go to (1-School, 2-Work, 3-Both)? "
transport_question: .asciiz "\nWhat do you take (1-Walk, 2-Bike, 3-Bus/Public Transit, 4-Personal Car, 5-Carpool)? "
miles_question: .asciiz "\nHow many miles do you travel daily? "
carpool_question: .asciiz "\nIf carpool, how many people (including yourself)? "
weekday_emission_result: .asciiz "\nYour weekday transportation emissions (kg CO2): "

# Emission factors (double-precision)
ef_bus: .double 0.1
ef_car: .double 0.3
ef_carpool: .double 0.3
zero_value: .double 0.0  # Default value for non-motorized modes


# set display to:
#	Pixels width and height to 4x4
#	Display width and height to 256x256
#	Base address = 0x10010000
# This will make our screen width 64x64 (256/4 = 64)
# 64 * 64 * 4 = 16384 required bytes

display:	.space 16384

define:
# screen information
	.eqv PIXEL_SIZE 4
	.eqv WIDTH 64
	.eqv HEIGHT 64
	.eqv DISPLAY 0x10000000

# colors
	.eqv	GRAY 	0x00A0A0A0
	.eqv	WHITE 	0x00FFFFFF
	.eqv	RED	0x00FF0000
	.eqv	YELLOW	0x00FFFF00
	.eqv	GREEN	0x0000FF00
	.eqv	BLUE	0x000000FF


.text
.globl main

main:
# set the frame pointer to the beginning of the stack
    move $fp, $sp       
    
    
	li $a0, WHITE		# set white as the background color
	jal backgroundColor	# color the background
	
	
	li $a0, 1		# set first bar starting x position to x = 1
	li $a1, 10		# set first bar starting x position to x = 10
	li $a2, 64		# set first bar height to 64
	li $a3, GRAY		# set color to gray
	jal drawBar		# draw bar

	li $a0, 14		# set first bar starting x position to x = 14
	li $a1, 23		# set first bar starting x position to x = 23
	li $a2, 64		# set first bar height to 64
	li $a3, GRAY		# set color to gray
	jal drawBar		# draw bar
	
	
	li $a0, 27		# set first bar starting x position to x = 27
	li $a1, 36		# set first bar starting x position to x = 36
	li $a2, 64		# set first bar height to 64
	li $a3, GRAY		# set color to gray
	jal drawBar		# draw bar
	
	li $a0, 40		# set first bar starting x position to x = 40
	li $a1, 49		# set first bar starting x position to x = 49
	li $a2, 64		# set first bar height to 64
	li $a3, GRAY		# set color to gray
	jal drawBar		# draw bar
	
	
	li $a0, 53		# set first bar starting x position to x = 53
	li $a1, 62		# set first bar starting x position to x = 62
	li $a2, 64		# set first bar height to 64
	li $a3, GRAY		# set color to gray
	jal drawBar		# draw bar

	
	
    # Input weekday transportation data
    jal handle_weekday_transportation

    # Display weekday transportation emissions
    jal display_weekday_emissions





    # Exit program
    li $v0, 10
    syscall

# Handle weekday transportation input and calculations
handle_weekday_transportation:
    addiu $sp, $sp, -8       # Allocate space on the stack
    sw $ra, 4($sp)           # Save return address to main
    sw $t0, 0($sp)           # Save temporary register $t0

    li $v0, 4
    la $a0, main_question
    syscall

    li $v0, 5
    syscall
    move $t0, $v0            # Save main choice (school/work/both)

    li $v0, 4
    la $a0, transport_question
    syscall

    li $v0, 5
    syscall
    move $t1, $v0            # Save transport mode

    beq $t1, 3, ask_miles    # If Bus/Public Transit
    beq $t1, 4, ask_miles    # If Personal Car
    beq $t1, 5, ask_miles    # If Carpool

    l.d $f0, zero_value      # Non-motorized emissions (default to 0)
    j cleanup_transportation

ask_miles:
    li $v0, 4
    la $a0, miles_question
    syscall

    li $v0, 7
    syscall
    mov.d $f2, $f0           # Save miles in $f2

    beq $t1, 5, ask_carpool  # If carpool
    jal calculate_motorized_emissions  # Otherwise, calculate emissions
    j cleanup_transportation

ask_carpool:
    li $v0, 4
    la $a0, carpool_question
    syscall

    li $v0, 5
    syscall
    move $t2, $v0            # Save carpool count

    jal calculate_motorized_emissions
    j cleanup_transportation

calculate_motorized_emissions:
    addiu $sp, $sp, -8       # Allocate space for local variables
    sw $t1, 0($sp)           # Save transport mode
    sw $t2, 4($sp)           # Save carpool count (if applicable)

    beq $t1, 3, load_bus
    beq $t1, 4, load_car
    beq $t1, 5, load_carpool

load_bus:
    l.d $f0, ef_bus          # Load bus emission factor
    j process_emission

load_car:
    l.d $f0, ef_car          # Load car emission factor
    j process_emission

load_carpool:
    l.d $f0, ef_carpool      # Load carpool emission factor
    lw $t2, 4($sp)           # Retrieve carpool count
    mtc1 $t2, $f4            # Move carpool count to FP register
    cvt.d.w $f4, $f4         # Convert carpool count to double
    div.d $f0, $f0, $f4      # Adjust emission factor for carpool
    j process_emission

process_emission:
    mul.d $f0, $f0, $f2      # Daily emissions = factor * miles
    li $t3, 5                # Weekdays multiplier
    mtc1 $t3, $f4            # Move multiplier to FP register
    cvt.d.w $f4, $f4         # Convert to double
    mul.d $f0, $f0, $f4      # Weekly emissions = daily emissions * 5

    lw $t1, 0($sp)           # Restore transport mode
    lw $t2, 4($sp)           # Restore carpool count
    addiu $sp, $sp, 8        # Deallocate local variables
    jr $ra                   # Returning control to handle_weekday_transportation

cleanup_transportation:
    lw $ra, 4($sp)           # Restore return address
    lw $t0, 0($sp)           # Restore $t0
    addiu $sp, $sp, 8        # Deallocate stack space
    jr $ra                   # Returning control to main

# Display the weekday transportation emissions
display_weekday_emissions:
    addiu $sp, $sp, -4       # Allocate space on the stack
    sw $ra, 0($sp)           # Save return address

# Example: Normalize emissions for a calculated $f0
jal normalize_emission  # Normalize the emission value in $f0
move $t4, $v0           # Save normalized height in $t3

	li $a0, 1		# set first bar starting x position to x = 1
	li $a1, 10		# set first bar starting x position to x = 10
	move $a2, $t4		# set first bar height to 64
	li $a3, GREEN		# set color to gray
	jal drawBar		# draw bar


    li $v0, 4
    la $a0, weekday_emission_result
    syscall

    li $v0, 3
    mov.d $f12, $f0          # Load emissions for printing
    syscall

    lw $ra, 0($sp)           # Restore return address
    addiu $sp, $sp, 4        # Deallocate stack space
    jr $ra                   # Returning control to main
    





# draws the background color
# precondition: $a0 is set the color
backgroundColor:
	
	li $s1, DISPLAY		# The first pixel on the display
		# set s2 = the last memory address of the display
	li $s2, WIDTH
	mul $s2, $s2, HEIGHT
	mul $s2, $s2, 4		# word
	add $s2, $s1, $s2

backgroundLoop:
	sw $a0, 0($s1)
	addiu $s1, $s1, 4
	ble $s1, $s2, backgroundLoop
	
	jr $ra



# draws pixels
# preconditions
#	$a0 = x
#	$a1 = y
#	$a2 = color

draw_pixel:
	
	addi $sp, $sp, -8		# make room on the stack for 2 words ($ra, $fp)
	sw $fp, 4($sp)
	addi $fp, $sp, 4	# move the $fp to the boginning of this stack frame
	sw $ra, -4($fp)

	# $s1 = address = DISPLAY + 4 * (x + (y * WIDTH))
	mul $s1, $a1, WIDTH	# s1 = (y * WIDTH)
	add $s1, $s1, $a0	# (x + s1)
	mul $s1, $s1, 4		# word (4 bytes)
	sw $a2, DISPLAY($s1)
	

	lw $ra, -4($fp)
	lw $fp, 0($fp)
	addi $sp, $sp, 8		# pop off the stack

	jr $ra
	




# draws vertical bars
# preconditions
#	$a0 = x (starting)
#	$a1 = x (ending)
#	$a2 = height
#	$a3 = color
drawBar:
	addi $sp, $sp, -8		# make room on the stack for 2 words ($ra, $fp)
	sw $fp, 4($sp)		# store frame pointer
	addi $fp, $sp, 4	# move the $fp to the beginning of this stack frame
	sw $ra, -4($fp)		# store return address

	li $s0, 65		# set y offset to bottom
	move $s3, $a0		# The starting x position
	move $s4, $a1		# The ending x position
	sub $s5, $s0, $a2	# set s5 to height of bar
	move $s6, $s3		# set s6 to reset s3 position

	move $a2, $a3		# set color

barLoopHorizontal:
	bgt $s3, $s4, barLoop	# if s3 > s4
	move $a0, $s3		# set x offset from s3
	move $a1, $s0		# set y offset from s4
	jal draw_pixel		# draw pixel
	
	addi $s3, $s3, 1	# move x one unit over
	j barLoopHorizontal

barLoop:
	blt $s0, $s5, barExit	# if s0 < s5
	move $s3, $s6		# The starting x position
	subi $s0, $s0, 1	# move y one position up
	j barLoopHorizontal
barExit:	
	lw $ra, -4($fp)			# restore return address
	lw $fp, 0($fp)			# restore frame pointer
	addi $sp, $sp, 8		# pop off the stack
	
	jr $ra





# Normalize emissions to a height in the range 0-64
# Preconditions:
#   $f0 = emission value (in kg CO₂)
# Postconditions:
#   $v0 = normalized height (integer 0-64)
normalize_emission:
	addi $sp, $sp, -8		# make room on the stack for 2 words ($ra, $fp)
	sw $fp, 4($sp)		# store frame pointer
	addi $fp, $sp, 4	# move the $fp to the beginning of this stack frame
	sw $ra, -4($fp)		# store return address



    li $s0, 45            # Assume max emission is 45 kg CO2
    mtc1 $s0, $f6          # Move 45 into $f6
    cvt.d.w $f6, $f6       # Convert 45 to double

    div.d $f8, $f0, $f6    # emission / 45 (normalize to 0-1)
    li $s1, 64             # Max height (64 pixels)
    mtc1 $s1, $f6          # Move 64 into $f6
    cvt.d.w $f6, $f6       # Convert 64 to double
    mul.d $f8, $f8, $f6    # emission_normalized * 64

    cvt.w.d $f8, $f8       # Convert result to integer
    mfc1 $v0, $f8          # Move result into $v0
    
    
    	lw $ra, -4($fp)			# restore return address
	lw $fp, 0($fp)			# restore frame pointer
	addi $sp, $sp, 8		# pop off the stack
    
    jr $ra