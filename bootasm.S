# When the PC starts, the processor is essentially emulating an 8086 processor, i.e. 
# a 16-bit processor.  So our initial boot loader code is 16-bit code that will 
# eventually switch the processor into 32-bit mode.

# This code is linked to assume a starting address of 0x7C00 which is where the BIOS
# will load a boot segment.

.code16                         # Assemble for 16-bit mode
.globl start
start:
    jmp     real_start

# Write to the console using BIOS.
# 
# Input: SI contains the address of the null-terminated string to be displayed

cons_write:
    movb    $0x0e, %ah           # 0x0e is the INT 10h BIOS call to output the value contained in AL to screen

cons_write_rpt:
    movb    (%si), %al          # Load the byte at the location contained in the SI register into AL   
    inc     %si                 # Add 1 to the value in SI
    cmp     $0, %al             # Compare the value in AL with 0
    jz      cons_write_done     # If it is zero, then we are done
    int     $0x10               # Output the character in AL to the screen
    jmp     cons_write_rpt      # and continue

cons_write_done:                # Something that is called will never return 
    ret                         # until a 'ret' instruction is encountered.  Labels do 
                                # not give a program any structure.  They just give a 
                                # memory location a name that we can use in our code. 

# write goes into write repeat and write done
# it is made to print a variable length string
# the three methods work together, write falls into write repeat, write will then jump to write done once the terminating 0 is reached
# ret  brings it down to where the call happened (in real_start in this case)

real_start:
    cli                         # BIOS enabled interrupts; disable

    # Zero data segment registers DS, ES, and SS.
    xorw    %ax, %ax            # Set %ax to zero
    movw    %ax, %ds            # -> Data Segment
    movw    %ax, %es            # -> Extra Segment
    movw    %ax, %ss            # -> Stack Segment

    movw    $0, %sp             # Set the stack to the top of the segment
    movw    $boot_message, %si  # Display our boot message
    call    cons_write
# can put my stuff before the endless loop
    movw    $boot_message, %si  # Duplicate the reset of si
    call cons_writeline
# don#t eat into the next label though

endless_loop:                   # Loop forever more
    jmp     endless_loop    

# start of w1 additions
cons_write_crlf:
    # output a CR (0x0D)
    movb $0x0e, %ah             # set AH to hex 0e, will be used by interupt 10 hex
    movb $0x0d, %al             # set AL to hex for line feed
    int $0x10                   # interupt 10 hex, uses ah contents to determine what to do. hes 0e means it will type out AL's contents
    # output an LF (0x0A)
    # movb $0x0e, %ah  # ah never gets changed, so line unnecacary
    movb $0x0a, %al             # change al contents
    int $0x10                   # run interupt again
    ret

cons_writeline:
    # put contents of the string whos ADDRESS is in si into al
    # ah to $0x0e in case it's changed itself oooooor
    call cons_write                 # write already exists to handle variable length strings that are stored in the adress that si points to
    call cons_write_crlf             # caqll line feed. this exists so it isn't method order dependant
    ret                         # ret needed here
# end of w1 additions

boot_message:                  # Definition of our boot message 
    .string "Boot Loader V1.0"

