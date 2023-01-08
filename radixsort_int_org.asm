.data
    	nl: .asciiz "\n"
    	display_address: .word 0x10008000
        max_size: .word 0x0001fc00
#
# Bitmap Display Configuration:
# - Unit width in pixels: 4                         
# - Unit height in pixels: 4
# - Display width in pixels: 1024
# - Display height in pixels: 512
# - Base Address for Display: 0x10008000 ($gp)
# - max value possible: 131068
#

.macro set_a3(%reg)
	lw $a3, max_size
        
        sub $a2, %reg, $s2
        
        add $a3, $a2, $a3 

.end_macro

.macro position_display(%colum_reference, %pixel_color, %value)	
    # $s3 is pixel color
    # $s4 is $gp
    # $a1 is array
    # $t2 is num 
        li $s6, %pixel_color
        lw $t9, display_address
    	add $t9, %colum_reference, $t9
    	li $s7, 0
        add $t2, %value, $0
.end_macro

.macro update_and_refresh_bitmap
	jal paint_col
	li	$v0,	39
	syscall
.end_macro

.macro exec(%call_num)
    li $v0, %call_num
    syscall
.end_macro

.macro dealloc(%val)
    lw $ra, 0($sp)
    addi $sp, $sp, %val
.end_macro

.macro alloc(%val)
    addi $sp, $sp, %val
    sw $ra, 0($sp)
.end_macro

.macro pause(%val)
    addi $sp,	$sp,	-4
    sw	$a0,	0($sp)
    
    addi $a0, $zero, %val
    addi $v0, $zero, 32
    syscall
    
    lw	$a0,	0($sp)
	
    addi $sp,	$sp,	4
.end_macro

.macro rand_value(%reg, %min,	%max)
	addi	$sp,	$sp,	-8
	
	sw	$a0,	0($sp)
	sw	$a1,	4($sp)
	addi	$a0,	$zero,	%min
	addi	$a1,	$zero,	%max
	addi	$v0,	$zero,	42
	syscall
	move	%reg,	$a0
	lw	$a1,	4($sp)
	lw	$a0,	0($sp)
	
	addi	$sp,	$sp,	8
.end_macro

.eqv red    0xff0000
.eqv white  0xffffff
.eqv black  0x000000
.eqv pause_time 5
.text
    main:
    # $s0 is array
    # $s1 is array end
    # $s2 is array start
    
        #// scanf("%i");
        # read array size
        exec(5)
        
        #// malloc(sizeof(int)*$a0);
        # multiply by 4 because int = 4 bytes
        # and save to s0
        mul $a0, $v0, 4
        
        #// malloc(sizeof(int)*$a0);
        # malloc $a0 bytes
        exec(9)
        
        #// $s0 = malloc(sizeof(int)*$a0);
        # copy array header 
        move $s0, $v0
        move $s2, $v0
        
        #// malloc(sizeof(int)*$a0);
        # find array end
        add $s1, $s0, $a0 

        lw $a3, max_size    
    
    main2:
    # $s0 is array
    # $s1 is array end
    # $s2 is array start
    # $s3 is max value
    # $t6 is exp
    
        #// scanf("%i");
        # read int
        rand_value($v0,	10, 100)
        
        #// $s0[i] = $f0;
        # save int to array at index i
        sw $v0, 0($s0)
        
        #// i++;
        # add index by 1 int = 4 bytes
        addi $s0, $s0, 4
        
        # paint each number
        position_display($a3,white,$v0)
        update_and_refresh_bitmap
        
        # set next collumn for paint
        addi $a3, $a3, 4

        lw $v1, -4($s0)

        jal max
        
        #// for(i = 0; i < $a0; i++);
        # verify if ther is int to read
        bne $s0, $s1, main2

        pause(pause_time)

        # int exp = 1
        li $t6, 1

        jal get_ra
        addi $ra, $ra, 16

        alloc(-4)
        
        #// radixsort($s0, $s1);
        # go to radix
        j radix
        
        move $s0, $s2
        
        #// print("\n")
        la $a0, nl
        exec(4)

    print:
    # $s0 is array
    # $s1 is array end
    # $s2 is array start
        
        #// print(%d)
        lw $a0, 0($s0)
        exec(1)
        
        #// print("\n")
        la $a0, nl
        exec(4)
        
        #// i++
        addi $s0, $s0, 4
        
        #// for(i = 0; i < $a0; i++);
        bne $s0, $s1, print
        
        #// return;
        # end program
        exec(10)      

    radix:
    # $s0 is array
    # $s1 is array end
    # $s2 is array start
    # $s3 is max value
    # $s4 is output[n]
    # $s5 is count[10]
    # $t6 is exp
    # $t5 is i

        #// m / exp
        div $t5, $s3, $t6
        
        #// m / exp > 0
        beq $t5, $0, return 

        #// malloc(sizeof(int)*$a0);
        # malloc $a0 bytes
        sub $a0, $s1, $s2
        exec(9)

        #// $s4 = malloc(sizeof(int)*$a0);
        # copy array header 
        move $s4, $v0

        li $t5, 10

        #// malloc(sizeof(int)*$a0);
        # malloc $a0 bytes
        mul $a0, $t5, 4
        exec(9)

        #// $s5 = malloc(sizeof(int)*$a0);
        # copy array header 
        move $s5, $v0

        #// int i = 0
        li $t5, 0

        #// countSort($s0, $s1 - $s2, $t6);
        jal countsort1

        #// exp *= 10
        mul $t6, $t6, 10

        j radix

    countsort1:
    # $s0 is array
    # $s1 is array end
    # $s2 is array start
    # $s3 is max value
    # $s4 is output[n]
    # $s5 is count[10]
    # $t6 is exp
    # $t5 is i    

        #// arr[i]
        add $t1, $s2, $t5
        lw $t0, 0($t1)

        #// arr[i] / exp
        div $t0, $t0, $t6

        #// (arr[i] / exp) % 10
        rem $t0, $t0, 10

        #// count[(arr[i] / exp) % 10]
        mul $t0, $t0, 4
        add $t1, $s5, $t0
        lw $t0, 0($t1)

        #// count[(arr[i] / exp) % 10]++;
        addi $t0, $t0, 1
        sw $t0, 0($t1)

        #// i++
        addi $t5, $t5, 4

        #// i < n
        sub $t0, $s1, $s2
        bgt $t0, $t5, countsort1 
        
        #// i = 1
        li $t5, 4

    countsort2:
    # $s0 is array
    # $s1 is array end
    # $s2 is array start
    # $s3 is max value
    # $s4 is output[n]
    # $s5 is count[10]
    # $t6 is exp
    # $t5 is i 

        #// count[i]
        add $t1, $s5, $t5
        lw $t0, 0($t1)
        mul $t0, $t0, 4

        #// count[i - 1]
        addi $t1, $t1, -4
        lw $t2, 0($t1)
        mul $t2, $t2, 4

        #// count[i] += count[i - 1]
        add $t0, $t0, $t2
        addi $t1, $t1, 4
        div $t0, $t0, 4
        sw $t0, 0($t1)

        #// i++
        addi $t5, $t5, 4

        #// i < 10
        blt $t5, 40, countsort2

        #// i = n - 1
        sub $t5, $s1, $s2
        addi $t5, $t5, -4

    countsort3:
    # $s0 is array
    # $s1 is array end
    # $s2 is array start
    # $s3 is max value
    # $s4 is output[n]
    # $s5 is count[10]
    # $t6 is exp
    # $t5 is i 

        #// arr[i]
        add $t1, $s2, $t5
        lw $t0, 0($t1)

        #// arr[i] / exp
        div $t0, $t0, $t6

        #// (arr[i] / exp) % 10
        rem $t0, $t0, 10

        #// count[(arr[i] / exp) % 10]
        mul $t0, $t0, 4
        add $t1, $s5, $t0
        lw $t0, 0($t1)

        #// count[(arr[i] / exp) % 10] - 1
        add $t0, $t0, -1

        #// count[(arr[i] / exp) % 10]--;
        sw $t0, 0($t1)
        mul $t0, $t0, 4

        #// output[count[(arr[i] / exp) % 10] - 1]
        add $t1, $t0, $s4

        #// arr[i]
        add $t0, $s2, $t5
        lw $t2, 0($t0)

        #// output[count[(arr[i] / exp) % 10] - 1] = arr[i];
        sw $t2, 0($t1)

        #// i--
        addi $t5, $t5, -4

        #// i >= 0
        bgez $t5, countsort3

        #// i = 0
        li $t5, 0
        
        alloc(-4)

    countsort4:
    # $s0 is array
    # $s1 is array end
    # $s2 is array start
    # $s3 is max value
    # $s4 is output[n]
    # $s5 is count[10]
    # $t6 is exp
    # $t5 is i 
    
        #// arr[i]
        sub $t0, $s1, $t5
        subi $t0, $t0, 4
        
        lw $t2, 0($t0)
        
        set_a3($t0)
        # paint numbers in red to be swapped
        position_display($a3,red,$t2)
        update_and_refresh_bitmap
        
        pause(pause_time)
        
        set_a3($t0)
        # paint numbers in black to be swapped
        position_display($a3,black,$s3)
        update_and_refresh_bitmap
        
        #// output[i]
        add $t1, $s4, $t5
        lw $t2, 0($t1)
        
        set_a3($t0)
        # paint numbers swapped in white
        position_display($a3,white,$t2)
        update_and_refresh_bitmap
        
        pause(pause_time)

        #// arr[i] = output[i]
        sw $t2, 0($t0)

        #// i++ 
        addi $t5, $t5, 4

        #// i < n
        sub $t1, $s1, $s2
        ble $t5, $t1, countsort4
        
        dealloc(4)

        jr $ra
    max:
        blt $v0, $v1, max2

        add $s3, $v0, $0

        jr $ra
    
    max2:
        add $s3, $v1, $0

        jr $ra
        
    return:
    	dealloc(4)
    
    get_ra:
    	jr $ra


    paint_col:
    
    	# store color to be shown
    	sw $s6, 0($t9)
    	
    	# decrements by 1 row
    	addi $t9, $t9, -1024
    	
    	# increments number counter by 1
    	addi $s7, $s7, 1
    	
    	# paint until number < number counter
    	ble $s7, $t2, paint_col
    	jr $ra
