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
        li $s3, %pixel_color
        lw $s4, display_address
    	add $s4, %colum_reference, $s4
    	li $t1, 0
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
        
        #//$s0 = malloc(sizeof(int)*$a0);
        # copy array header 
        move $s0, $v0
        move $s2, $v0
        
        #// malloc(sizeof(int)*$a0);
        # find array end
        add $s1, $s0, $a0 

	# setting up the dispaly stack
        lw $a3, max_size    
    
    main2:
    # $s0 is array
    # $s1 is array end
    # $s2 is array start
    
        #// scanf("%i");
        # read int
        #exec(5)
        rand_value($v0, 1, 120)
        
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
        
        #// for(i = 0; i < $a0; i++);
        # verify if ther is int to read
        bne $s0, $s1, main2

        pause(pause_time)
        
        #// i--;
        # correct index to be at last number
        addi $s0, $s0, -4
    
        #// $k1 = i-1;
        add $k1, $s0, $0
        
        #// $k0 = 0;
        move $k0, $s2
    
        #// qsort($s0,$k0,$k1);
        # go to qsort
        jal qsort
        
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
        
    qsort:
    # $s0 is array
    # $s1 is array end
    # $s2 is array start
    # $k0 is low
    # $k1 is high
    # $t3 is pivot
        
        # prepares stack for inseting n regs
        alloc(-12)
        sw $k1, 4($sp)
        
        #// if (low < high);
        # verify if recursion is done
        bge $k0, $k1, return
        
        #// partition($s0, $k0, $k1)
        # organizes partition
        jal partition
        
        # saves $k1, $k0 and $t3
        sw $t3, 8($sp)
        
        #// quickSort($s0, $k0, $t3 - 1);
        #// $t3 - 1
        addi $k1, $t3, -4
        
        jal qsort
        
        # loads $k1 and $t3
        lw $k1, 4($sp)
        lw $t3, 8($sp)
        
        #// quickSort($s0, $t3 + 1, $k1);
        #// $t3 + 1
        addi $k0, $t3, 4
        jal qsort

        j return
        
    partition:
    # $s0 is counter (array)
    # $s1 is array end
    # $s2 is array start
    # $k0 is low
    # $k1 is high
    # $t3 is index
    # $t4 is end
    # $t5 is array[high] (pivot)
    
        # prepares stack for inseting n regs
        alloc(-4)
        
        #// $t2 = array[high]
        lw $t5, 0($k1)
        
        #// $t3 = low - 1
        addi $t3, $k0, -4
        
        #// $s0 (j) = "low"
        addi $s0, $k0, -4
        
        #// $t4 = "high - 1"
        addi $t4, $k1, -4
        
        # readies $ra for partition2
        jal partition2
        
    partition2:
    # $s0 is array
    # $s1 is array end
    # $s2 is array start
    # $k0 is low
    # $k1 is high
    # $t3 is index
    # $t4 is end
    # $t5 is array[high] (pivot) 
    # $t6 is array[j]
    
        #// j++;
        # increments counter
        addi $s0, $s0, 4

        lw $t6, 0($s0)
        
        #// if (arr[j] < pivot);
        blt $t6, $t5, smaller
        
        #// for (int j = low; j <= high - 1; j++);
        ble $s0, $t4, partition2
        
    partition3:   
    # $s0 is array
    # $s1 is array end
    # $s2 is array start
    # $k0 is low
    # $k1 is high
    # $t3 is index
    # $t4 is end
    # $t5 is array[high] (pivot) 
    # $t6 is array[j]
     
    	#// i++;
    	addi $t3, $t3, 4
    	
    	#// $t0 = high;
    	move $s0, $k1
    	
    	#// swap(arr, i + 1, high);
        jal swap
        
        # dealloc stack pointer
        lw $ra, 0($sp)
        addi $sp, $sp, 4
        
        jr $ra
    
    smaller:
        #// i++; 
        addi $t3, $t3, 4    
    swap:

        addi $sp, $sp, -4
        sw $ra, 0($sp)

        # $f0 and $f1 to swap
        # load
        lw $t8, 0($s0)
        lw $t9, 0($t3)
        
       
        set_a3($t3)
        
        # paint numbers in red to be swapped
        position_display($a3,red,$t9)
        update_and_refresh_bitmap
        
        set_a3($s0)
        
        # paint numbers in red to be swapped
        position_display($a3,red,$t8)
        update_and_refresh_bitmap
        
        pause(pause_time)

	# clear numbers from the screen
        position_display($a3,black,$t8)
        update_and_refresh_bitmap
        
        set_a3($t3)
        
        # clear numbers from the screen
        position_display($a3,black,$t9)
        update_and_refresh_bitmap
        
        # swap
        move $t7, $t8
        move $t8, $t9
        move $t9, $t7

	# paint new number in the position
        position_display($a3,white,$t9)
        update_and_refresh_bitmap
        
        set_a3($s0)
        
        # paint new number in the position
        position_display($a3,white,$t8)
        update_and_refresh_bitmap
        
        pause(pause_time)

        # store
        sw $t8, 0($s0)
        sw $t9, 0($t3)

        dealloc(4)
        
        jr $ra

    return:
    
        # dealloc stack pointer
        dealloc(12)
        
        jr $ra
        
    paint_col:
    
    	# store color to be shown
    	sw $s3, 0($s4)
    	
    	# decrements by 1 row
    	addi $s4, $s4, -1024
    	
    	# increments number counter by 1
    	addi $t1, $t1, 1
    	
    	# paint until number < number counter
    	ble $t1, $t2, paint_col
    	jr $ra

