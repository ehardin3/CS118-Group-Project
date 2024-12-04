# Weekday Transportation 
# This module calculates the weekday transportation emissions 

.data
# Prompts for weekday transportation
main_question: .asciiz "\nDo you go to (1-School, 2-Work, 3-Both)? "
transport_question: .asciiz "\nWhat do you take (1-Walk, 2-Bike, 3-Bus/Public Transit, 4-Personal Car, 5-Carpool)? "
miles_question: .asciiz "\nHow many miles do you travel daily? "
carpool_question: .asciiz "\nIf carpool, how many people (including yourself)? "
weekday_emission_result: .asciiz "\nYour weekday transportation emissions (kg CO2): "

# Prompts for weekday energy
solar_question: .asciiz "\nDo you have solar panels installed? (1-Yes, 2-No): "
bulb_question: .asciiz "\nDo you use LED bulbs or Incandescent bulbs? (1-LED, 2-Incandescent): "
light_hours_question: .asciiz "\nHow many hours do you leave your lights on daily? (0-24): "
invalid_hours_msg: .asciiz "\nInvalid input! Please enter a value between 0 and 24."
heater_or_blanket_question: .asciiz "\nDo you use a heater or just a blanket? (1-Heater, 2-Blanket): "
heater_hours_question: .asciiz "\nHow many hours do you use the heater daily? (0-24): "
weekday_energy_result: .asciiz "\nYour weekday energy emissions (kg CO2): "

# Emission factors (double-precision)
ef_bus: .double 0.1            # Public transit (kg CO2 per mile)
ef_car: .double 0.3            # Personal car (kg CO2 per mile)
ef_carpool: .double 0.3        # Carpool (kg CO2 per mile, adjusted by passengers)
zero_value: .double 0.0        # Non-motorized transport
ef_led: .double 0.01           # LED light bulb (kg CO2 per hour)
ef_incandescent: .double 0.05  # Incandescent bulb (kg CO2 per hour)
ef_heater: .double 1.5         # Heater (kg CO2 per hour)
ef_blanket: .double 0.0        # Blanket (no emissions)

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
    
     # Input weekday energy data
    jal handle_weekday_energy





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
    
    jal emission_sound
    
    
    

    lw $ra, 0($sp)           # Restore return address
    addiu $sp, $sp, 4        # Deallocate stack space
    jr $ra                   # Returning control to main
    
# handle_weekday_energy
# Calculates weekday energy emissions based on user inputs.
# Precondition:
# - $a0 is used to display prompts for each question.
# - The user must provide valid inputs for:
#   1) Solar panel installation status (1-Yes, 2-No).
#   2) Light bulb type (1-LED, 2-Incandescent).
#   3) Daily light usage hours (0-24).
#   4) Heating method (1-Heater, 2-Blanket).
# Postcondition:
# - $f12 will contain the total weekday energy emissions in kg CO2.
# - Emissions are calculated using the following factors:
#   1) LED bulbs: 0.01 kg CO2 per hour.
#   2) Incandescent bulbs: 0.05 kg CO2 per hour.
#   3) Heater: 1.5 kg CO2 per hour.
#   4) Blanket: 0.0 kg CO2 per hour.
handle_weekday_energy:
    addiu $sp, $sp, -8       # Allocate stack space
    sw $ra, 4($sp)           # Save return address
    sw $t0, 0($sp)           # Save temporary register $t0

    # Question 1: Solar Panels
    li $v0, 4
    la $a0, solar_question
    syscall

    li $v0, 5
    syscall
    move $t0, $v0            # Save solar panel choice

    # Question 2: Light Bulb Type
    li $v0, 4
    la $a0, bulb_question
    syscall

    li $v0, 5
    syscall
    move $t1, $v0            # Save light bulb type

    # Question 3: Light Usage Hours (Allow 0-24)
light_hours_prompt:
    li $v0, 4
    la $a0, light_hours_question
    syscall

    li $v0, 5
    syscall
    blt $v0, 0, invalid_hours   # Check if input is below 0
    bgt $v0, 24, invalid_hours  # Check if input is above 24
    move $t2, $v0               # Save valid light usage hours
    j valid_hours

invalid_hours:
    li $v0, 4
    la $a0, invalid_hours_msg   # Display invalid input message
    syscall
    j light_hours_prompt        # Retry the question

valid_hours:
    # Question 4: Heater or Blanket
    li $v0, 4
    la $a0, heater_or_blanket_question
    syscall

    li $v0, 5
    syscall
    move $t3, $v0               # Save heating choice

    # Calculate Light Bulb Emissions
    beq $t1, 1, use_led         # If LED
    beq $t1, 2, use_incandescent # If Incandescent

use_led:
    l.d $f0, ef_led             # Load LED emission factor
    j calculate_light_emissions

use_incandescent:
    l.d $f0, ef_incandescent    # Load incandescent emission factor

calculate_light_emissions:
    mtc1 $t2, $f4               # Move hours to floating-point register
    cvt.d.w $f4, $f4            # Convert hours to double
    mul.d $f6, $f0, $f4         # Total light bulb emissions = EF * hours

    # Calculate Heater or Blanket Emissions
    beq $t3, 1, use_heater      # If Heater
    beq $t3, 2, use_blanket     # If Blanket

use_heater:
    l.d $f0, ef_heater          # Load heater emission factor
    mul.d $f8, $f0, $f4         # Total heater emissions = EF * hours
    j sum_energy_emissions

use_blanket:
    l.d $f8, ef_blanket         # Load blanket emission factor (0 emissions)
    j sum_energy_emissions

sum_energy_emissions:
    add.d $f10, $f6, $f8        # Total energy emissions = light + heater/blanket

    # Multiply by 5 for weekday total
    li $t4, 5
    mtc1 $t4, $f4
    cvt.d.w $f4, $f4
    mul.d $f12, $f10, $f4       # Weekly energy emissions

    # Display result
    li $v0, 4
    la $a0, weekday_energy_result
    syscall

    li $v0, 3
    mov.d $f12, $f12            # Load result for printing
    syscall
    
    j emission_sound

    # Cleanup
    lw $ra, 4($sp)              # Restore return address
    lw $t0, 0($sp)              # Restore $t0
    addiu $sp, $sp, 8           # Deallocate stack space
    jr $ra                      # Return to main




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
#   $f0 = emission value (in kg CO?)
# Postconditions:
#   $v0 = normalized height (integer 0-64)
normalize_emission:
	addi $sp, $sp, -8		# make room on the stack for 2 words ($ra, $fp)
	sw $fp, 4($sp)		# store frame pointer
	addi $fp, $sp, 4	# move the $fp to the beginning of this stack frame
	sw $ra, -4($fp)		# store return address



    li $s0, 300            # Assume max emission is 45 kg CO2
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
    
    
# emission_sound: Generates a sound effect corresponding to the emission level.
# Precondition:
#   - $f12 contains the calculated emission value (a double-precision floating-point number).
#   - The thresholds for low, medium, and high emissions are defined in memory as:
#       low_threshold:  The maximum value for low emissions.
#       high_threshold: The minimum value for high emissions.
# Postcondition:
#   - Plays a sound based on the emission level:
#       Low emissions: High pitched sound
#       Medium emissions: Medium-pitched sound.
#       High emissions: Low pitched sound
emission_sound:
    addi $sp, $sp, -8          	# Allocate stack space
    sw $ra, 4($sp)             	# Save return address
    sw $t0, 0($sp)             	# Save temporary register $t0

    # Convert $f12 (double) to integer in $t1
    cvt.w.d $f2, $f12           # Convert emission value to integer
    mfc1 $t1, $f2              	# Move integer value to $t1

    # Calculate multiple of 20
    li $t2, 20                 	# Set divisor (20)
    div $t3, $t1, $t2          	# $t3 = emission / 20 (integer division)

    # Use $t3 to determine the message
    beqz $t3, low_emission_sound     # If $t3 == 0, it's less than 20
    li $t4, 2                  		# Example: Check if it's 40 or more
    bge $t3, $t4, high_emission_sound
    
    jal medium_emission_sound	# if value is in between low and high, jumps to medium_emission
    
    

low_emission_sound:

	li $a2 9	# loads chromatic percussion
	li $a3 127	# sets volume at max

	li $a0 65	# sets the pitch to E# or F
	li $a1 800	# duration 8/10 second
	li $v0 33	# play sound
	syscall

	li $a0 100	#rest 1/10 second
	li $v0 32
	syscall

	li $a0 62	# sets the pitch to D
	li $a1 800
	li $v0 33
	syscall

	li $a0 100	#rest 1/10 second
	li $v0 32
	syscall

	li $a0 67	# sets the pitch to G
	li $a1 800	# duration = 8/10 second
	li $v0 33	# plays sound
	syscall

	li $a0 200	# rest 2/10 second
	li $v0 32
	syscall

	li $a0 69	# sets pitch to A
	li $a1 2000	# duration = 2 seconds
	li $v0 33	# plays sound
	syscall

	li $a0 100	# rest 1/10 second
	li $v0 32
	syscall
  j cleanup_message
  
medium_emission_sound:

	li $a2 64 	#sets instrument to reed
	li $a3 127	#sets to max volume

	li $a0 49	# sets to low pitch
	li $a1 1500	# duration = 1.5 seconds
	li $v0 33	# plays sound
	syscall

	li $a0 100	# rest 1/10 second 
	li $v0 32
	syscall

	li $a0 37	#sets to a lower pitch
	li $a1 1500	# duration = 1.5 seconds
	li $v0 33	# plays sound
	syscall
j cleanup_message

high_emission_sound:

	li $a2 57	# sets instrument to brass
	li $a3 127	# max volume

	li $a0 65	# sets pitch to E# or F
	li $a1 800	# duration = 8/10 second
	li $v0 33	# play sound
	syscall

	li $a0 100	#rest 1/10 second
	li $v0 32
	syscall

	li $a0 62	# sets pitch to D
	li $a1 800	# duration = 8/10 second
	li $v0 33
	syscall

	li $a0 100	# rest 1/10 second
	li $v0 32
	syscall

	li $a0 49	# sets to a low pitch
	li $a1 800	# duartion = 8/10 second
	li $v0 33
	syscall

	li $a0 200	# rest 2/10 scond
	li $v0 32
	syscall

	li $a0 37	# sets to lower pitch
	li $a1 2000	# duration = 2 seconds
	li $v0 33
	syscall

	li $a0 100
	li $v0 32
	syscall

j cleanup_message

cleanup_message:
    	lw $ra, 4($sp)             # Restore return address
    	lw $t0, 0($sp)             # Restore $t0
    	addi $sp, $sp, 8           # Deallocate stack space
    	jr $ra                     # Return to caller

