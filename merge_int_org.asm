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
        lw $s5, display_address
    	add $s5, %colum_reference, $s5
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
    # $s3 is L[]
    # $s4 is R[]
    
        #// scanf("%i");
        # read array end
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

        #// malloc(sizeof(int)*$a0);
        # malloc $a0 bytes
        exec(9)

        #//$s3 = malloc(sizeof(int)*$a0);
        # copy array header 
        move $s3, $v0

        #// malloc(sizeof(int)*$a0);
        # malloc $a0 bytes
        exec(9)

        #//$s3 = malloc(sizeof(int)*$a0);
        # copy array header 
        move $s4, $v0

        lw $a3, max_size   
    
    main2:
    # $s0 is array
    # $s1 is array end
    # $s2 is array start
    
        #// scanf("%i");
        # read int
        rand_value($v0,1, 120)
        
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

        #// for(i = 0; i < $s1; i++);
        # verify if ther is int to read
        bne $s0, $s1, main2

        pause(pause_time)
        
        # reset t1
        #li $t1, 0
        
        #// i--;
        # correct index to be at last number
        addi $s0, $s0, -4
    
        #// $k1 = i-1;
        sub $k1, $s0, $s2
        
        #// $k0 = 0;
        li $k0, 0
    
        #// qsort($s0,$k0,$k1);
        # go to qsort
        jal sort
        
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
        
    sort:
    # $s0 is array
    # $s1 is array end
    # $s2 is array start
    # $k0 is left
    # $k1 is right
    # $t3 is mid
        
        # prepares stack for inseting n regs
        alloc(-16)
        sw $k1, 4($sp)
        sw $k0, 8($sp)
        
        #// if (right <= left);
        # verify if recursion is done
        bge $k0, $k1, return
        
        #// (r - l)
        sub $t3, $k1, $k0

        #// (r - l) / 2;
        div $t3, $t3, 8
        mul $t3, $t3, 4

        #// m = l + (r - l) / 2;
        add $t3, $t3, $k0

        # saves $k1, $k0 and $t3
        sw $t3, 12($sp)

        add $k1, $t3, $0

        #// partition($s0, $k0, $t3)
        # organizes partition
        jal sort
        
        # saves $k1, $k0 and $t3
        lw $k1, 4($sp)
        lw $t3, 12($sp)

        #// quickSort($s0, $t3 + 1, $k1);
        #// $t3 + 1
        addi $k0, $t3, 4
        jal sort
        
        # loads $k1 and $t3
        lw $k1, 4($sp)
        lw $k0, 8($sp)
        lw $t3, 12($sp)
        
        #// merge($s0, $k0, $t3, $k1);
        jal merge1

        j return

    merge1:
    # $k0 is left
    # $k1 is right
    # $t3 is mid
    # $t6 is i
    # $t7 is n1
    # $t8 is n2
    # $t9 is k

        #// l + 1
        addi $t7, $t3, 4
        #// n1 = m - l + 1
        #sub $t7, $t3, $k0
        sub $t7, $t7, $k0

        #// n2 = r - m
        sub $t8, $k1, $t3   

        #// k = l
        add $t9, $k0, $0

        #// i = 0
        li $t6, 0

    merge2:
    # $s2 is array start
    # $s3 is L[]
    # $k0 is left
    # $t6 is i
    # $t7 is n1

        #// L[i]
        add $t0, $s3, $t6 

        #// l + i
        add $t1, $k0, $t6
        
        #// arr[l+i]
        add $t1, $t1, $s2
        lw $t2, 0($t1)

        #// L[i] = arr[l + i]
        sw $t2, 0($t0)

        #// i++
        addi $t6, $t6, 4

        #// i < n1
        blt $t6, $t7, merge2

        #// i = 0
        li $t6, 0

    merge3:
    # $s2 is array start
    # $s4 is R[]
    # $t3 is mid
    # $t5 is j
    # $t6 is i
    # $t8 is n2

        #// R[i]
        add $t0, $s4, $t6 

        #// m + i
        add $t1, $t3, $t6
        
        #// m + i + 1
        addi $t1, $t1, 4
        
        #// arr[m + 1 + i]
        add $t1, $t1, $s2
        lw $t2, 0($t1)

        #// R[i] = arr[m + 1 + i]
        sw $t2, 0($t0)

        #// i++
        addi $t6, $t6, 4

        #// i < n2
        blt $t6, $t8, merge3

        #// i = 0
        li $t6, 0

        #// j = 0
        li $t5, 0

    merge4_1:
    # $s0 is array
    # $s1 is array end
    # $s2 is array start
    # $s3 is L[]
    # $s4 is R[]
    # $k0 is left
    # $k1 is right
    # $t3 is mid
    # $t5 is j
    # $t6 is i
    # $t7 is n1
    # $t8 is n2
    # $t9 is k
    
    	#// i < n1
        sle $t0, $t7, $t6

        #// j < n2
        sle $t1, $t8, $t5

        #// i < n1 && j < n2
        or $t0, $t1, $t0

        #// while (i < n1 && j < n2)
        bnez $t0, merge5  

        #// L[i]
        add $t0, $s3, $t6
        lw $t0, 0($t0)

        #// R[j]
        add $t1, $s4, $t5
        lw $t1, 0($t1)

        #// if (L[i] <= R[j])
        ble $t0, $t1, lefti

        #// arr[k]
        add $t0, $s2, $t9
        
        lw $t2, 0($t0)
        set_a3($t0)
        
        # paint numbers in red to be swapped
        position_display($a3,red,$t2)
        update_and_refresh_bitmap
        
        pause(pause_time)
        
        set_a3($t0)
        # paint numbers in black to be swapped
        position_display($a3,black,$t2)
        update_and_refresh_bitmap
        
        set_a3($t0)
        # paint numbers swapped in white
        position_display($a3,white,$t1)
        update_and_refresh_bitmap
        
        pause(pause_time)

        #// arr[k] = R[j]
        sw $t1, 0($t0)

        #// j++
        addi $t5, $t5, 4

    merge4_2:
    # $s0 is array
    # $s1 is array end
    # $s2 is array start
    # $s3 is L[]
    # $s4 is R[]
    # $k0 is left
    # $k1 is right
    # $t3 is mid
    # $t5 is j
    # $t6 is i
    # $t7 is n1
    # $t8 is n2
    # $t9 is k

        #// k++
        addi $t9, $t9, 4
    
    	j merge4_1
          

    merge5:
    # $s0 is array
    # $s1 is array end
    # $s2 is array start
    # $s3 is L[]
    # $s4 is R[]
    # $k0 is left
    # $k1 is right
    # $t3 is mid
    # $t5 is j
    # $t6 is i
    # $t7 is n1
    # $t8 is n2
    # $t9 is k
    
    	#// while(i < n1)
        bge $t6, $t7, merge6

        #// arr[k]
        add $t0, $s2, $t9
        
        
        lw $t2, 0($t0)
        set_a3($t0)
        
        # paint numbers in red to be swapped
        position_display($a3,red,$t2)
        update_and_refresh_bitmap
        
        pause(pause_time)
        
        set_a3($t0)
        # paint numbers in black to be swapped
        position_display($a3,black,$t2)
        update_and_refresh_bitmap

        #// L[i]
        add $t1, $s3, $t6
        lw $t2, 0($t1)
        
        set_a3($t0)
        # paint numbers swapped in white
        position_display($a3,white,$t2)
        update_and_refresh_bitmap
        
        pause(pause_time)

        #// arr[k] = L[i]
        sw $t2, 0($t0)

        #// k++
        addi $t9, $t9, 4

        #// i++
        addi $t6, $t6, 4
        
        j merge5

    merge6:
    # $s0 is array
    # $s1 is array end
    # $s2 is array start
    # $s3 is L[]
    # $s4 is R[]
    # $k0 is left
    # $k1 is right
    # $t3 is mid
    # $t5 is j
    # $t6 is i
    # $t7 is n1
    # $t8 is n2
    # $t9 is k
    
    	#// while(i < n1)
        bge $t5, $t8, return

        #// arr[k]
        add $t0, $s2, $t9
        
        lw $t2, 0($t0)
        set_a3($t0)
        
        # paint numbers in red to be swapped
        position_display($a3,red,$t2)
        update_and_refresh_bitmap
        
        pause(pause_time)
        
        set_a3($t0)
        # paint numbers in black to be swapped
        position_display($a3,black,$t2)
        update_and_refresh_bitmap

        #// R[j]
        add $t1, $s4, $t5
        lw $t2, 0($t1)
        
        set_a3($t0)
        # paint numbers swapped in white
        position_display($a3,white,$t2)
        update_and_refresh_bitmap
        
        pause(pause_time)

        #// arr[k] = R[j]
        sw $t2, 0($t0)

        #// k++
        addi $t9, $t9, 4

        #// j++
        addi $t5, $t5, 4
        
        j merge6

    return:
    
        # dealloc stack pointer
        dealloc(16)
        
        jr $ra

    lefti:

	#// arr[k]
        add $t1, $s2, $t9

	lw $t2, 0($t1)
        set_a3($t1)
        
        # paint numbers in red to be swapped
        position_display($a3,red,$t2)
        update_and_refresh_bitmap
        
        pause(pause_time)
        
        set_a3($t1)
        # paint numbers in black to be swapped
        position_display($a3,black,$t2)
        update_and_refresh_bitmap
        
        set_a3($t1)
        # paint numbers swapped in white
        position_display($a3,white,$t0)
        update_and_refresh_bitmap
        
        pause(pause_time)
        
        #// arr[k] = L[i]
        sw $t0, 0($t1)
        
        #// i++
        addi $t6, $t6, 4

        j merge4_2
        
	
    paint_col:
    
    	# store color to be shown
    	sw $s6, 0($s5)
    	
    	# decrements by 1 row
    	addi $s5, $s5, -1024
    	
    	# increments number counter by 1
    	addi $s7, $s7, 1
    	
    	# paint until number < number counter
    	ble $s7, $t2, paint_col
    	jr $ra

