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

.text
.globl main

main:
    # Initialize stack pointer
    li $sp, 0x7fffeff8       

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

    li $v0, 4
    la $a0, weekday_emission_result
    syscall

    li $v0, 3
    mov.d $f12, $f0          # Load emissions for printing
    syscall

    lw $ra, 0($sp)           # Restore return address
    addiu $sp, $sp, 4        # Deallocate stack space
    jr $ra                   # Returning control to main
