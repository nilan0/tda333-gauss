### Text segment
	.text
start:
	la		$a0, matrix_4x4		# a0 = A (base address of matrix)
	li		$a1, 4    		    # a1 = N (number of elements per row)
	li		$a2, 2				# a2 = B
	
								# <debug>
	jal 	print_matrix	    # print matrix before elimination
	nop							# </debug>
	jal 	eliminate			# triangularize matrix!
	nop							# <debug>
	jal 	print_matrix		# print matrix after elimination
	nop							# </debug>
	jal 	exit

exit:
	li   	$v0, 10          	# specify exit system call
	syscall						# exit program

################################################################################
# eliminate - Triangularize matrix.
#
# Args:		$a0  - base address of matrix (A)
#			$a1  - number of elements per row (N)

eliminate:
	# If necessary, create stack frame, and save return address from ra
	addiu	$sp, $sp, -4		# allocate stack frame
	sw		$ra, 0($sp)			# done saving registers
	
	##
	## Implement eliminate here
	## 

.eqv	_I	$t8
.eqv	_J	$t9
.eqv	_j	$t6
.eqv	_i	$t5
#.eqv	M	$v0
.eqv	_A	$a0
.eqv	_N	$a1
.eqv	_B	$a2
.eqv	_k  $t7
.eqv	_M	$s0

# TODO:
div		_N, _B
mflo	_M


	move	_I, $zero
loop_block_rows:
	move	$s1, _I
	add		$s1, $s1, _M
	add		$s1, $s1, -1
	
	move	_J, $zero
loop_block_cols:
	move	$s2, _J
	add		$s2, $s2, _M
	add		$s2, $s2, -1

# Init loop_pivot
	move	_k, $zero
	
# min(I, J)
	move	$t0, $s1
	# BRANCH DELAY SLOT?
	ble		$s1, $s2, end_min
	move	$t0, $s2
end_min:

loop_pivot_elems:

if_elem_in_block:
	blt		_k, _I, loop_below_pivot_row
	bgt		_k, $s1, loop_below_pivot_row

	#Max
	add		$t0, _k, 1
	move	_j, $t0
	# BRANCH DELAY SLOT?
	bge		$t0, _J, end_max
	move	_j, _J
end_max:

	# $t1 A[k][k]
	move	$t1, _k
	mul		$t1, $t1, _M
	add		$t1, $t1, _k
	sll		$t1, $t1, 2
	add		$t1, $t1, _A
loop_calc:
	# $t0 [k][j]
	move	$t0, _k
	mul		$t0, $t0, _M
	add		$t0, $t0, _j
	sll		$t0, $t0, 2
	add		$t0, $t0, _A

	lwc1	$f0, ($t0)
	lwc1	$f1, ($t1)

	div.s	$f0, $f0, $f1
	swc1	$f0, ($t0)

	#lw		$t2, ($t0)
	#lw		$t3, ($t1)

	#div		$t2, $t3
	#mflo	$t2			# move from lo

	#sw		$t2, ($t0)

end_loop_calc:
	ble		_k, $s2, loop_calc
	addiu	_k, _k, 1

if_elem_last:
	bne		_j, _N, loop_below_pivot_row
	li		$t0, 1
	sw		$t0, ($t1)
	
#####################################
	#Max
	add		$t0, _k, 1
	move	_i, $t0
	# BRANCH DELAY SLOT?
	bge		$t0, _I, loop_below_pivot_row
	move	_i, _I

loop_below_pivot_row:
	

	# $t1 A[i][k]
	move	$t1, _i
	mul		$t1, $t1, _M
	add		$t1, $t1, _k
	sll		$t1, $t1, 2
	add		$t1, $t1, _A


#Max
	add		$t0, _k, 1
	move	_j, $t0
	# BRANCH DELAY SLOT?
	bge		$t0, _J, loop_block_row
	move	_j, _J
	
loop_block_row:
	# $t0 [k][j]
	move	$t0, _k
	mul		$t0, $t0, _M
	add		$t0, $t0, _j
	sll		$t0, $t0, 2
	add		$t0, $t0, _A

	# $t2 [i][j]
	move	$t2, _i
	mul		$t2, $t2, _M
	add		$t2, $t2, _j
	sll		$t2, $t2, 2
	add		$t2, $t2, _A

	lwc1	$f0, ($t2)
	lwc1	$f1, ($t1)
	lwc1	$f2, ($t0)

	mul.s	$f1, $f1, $f2
	sub.s	$f0, $f0, $f1

	swc1	$f0, ($t2)

	#lw		$t3, ($t2)
	#lw		$t4, ($t1)
	#lw		$t0, ($t0)

	#mul		$t4, $t4, $t0
	#subu	$t3, $t3, $t4

	#sw		$t3, ($t2)

end_loop_block_row:
	ble		_j, $s2, loop_block_row
	addiu	_j, _j, 1

# if_elem_last:
	bne		_j, _N, end_loop_below_pivot_row
	nop
	sw		$zero, ($t1)

####################################

end_loop_below_pivot_row:
	ble		_i, $s1, loop_below_pivot_row
	addiu	_i, _i, 1

end_loop_pivot_elem:
	ble		_k, $t0, loop_pivot_elems
	addiu	_k, _k, 1

end_loop_block_cols:
	blt		_J, _N, loop_block_cols
	addu	_J, _J, _M
	
end_loop_block_rows:
	blt		_I, _N, loop_block_rows
	addu	_I, _I, _M
	

	lw		$ra, 0($sp)			# done restoring registers
	addiu	$sp, $sp, 4			# remove stack frame

	jr		$ra					# return from subroutine
	nop							# this is the delay slot associated with all types of jumps

################################################################################
# getelem - Get address and content of matrix element A[a][b].
#
# Argument registers $a0..$a3 are preserved across calls
#
# Args:		$a0  - base address of matrix (A)
#			$a1  - number of elements per row (N)
#			$a2  - row number (a)
#			$a3  - column number (b)
#						
# Returns:	$v0  - Address to A[a][b]
#			$f0  - Contents of A[a][b] (single precision)
getelem:
	addiu	$sp, $sp, -12		# allocate stack frame
	sw		$s2, 8($sp)
	sw		$s1, 4($sp)
	sw		$s0, 0($sp)			# done saving registers
	
	sll		$s2, $a1, 2			# s2 = 4*N (number of bytes per row)
	multu	$a2, $s2			# result will be 32-bit unless the matrix is huge
	mflo	$s1					# s1 = a*s2
	addu	$s1, $s1, $a0		# Now s1 contains address to row a
	sll		$s0, $a3, 2			# s0 = 4*b (byte offset of column b)
	addu	$v0, $s1, $s0		# Now we have address to A[a][b] in v0...
	l.s		$f0, 0($v0)		    # ... and contents of A[a][b] in f0.
	
	lw		$s2, 8($sp)
	lw		$s1, 4($sp)
	lw		$s0, 0($sp)			# done restoring registers
	addiu	$sp, $sp, 12		# remove stack frame
		
	jr		$ra					# return from subroutine
	nop							# this is the delay slot associated with all types of jumps

################################################################################
# print_matrix
#
# This routine is for debugging purposes only. 
# Do not call this routine when timing your code!
#
# print_matrix uses floating point register $f12.
# the value of $f12 is _not_ preserved across calls.
#
# Args:		$a0  - base address of matrix (A)
#			$a1  - number of elements per row (N) 
print_matrix:
	addiu	$sp,  $sp, -20		# allocate stack frame
	sw		$ra,  16($sp)
	sw      $s2,  12($sp)
	sw		$s1,  8($sp)
	sw		$s0,  4($sp) 
	sw		$a0,  0($sp)		# done saving registers

	move	$s2,  $a0			# s2 = a0 (array pointer)
	move	$s1,  $zero			# s1 = 0  (row index)
loop_s1:
	move	$s0,  $zero			# s0 = 0  (column index)
loop_s0:
	l.s		$f12, 0($s2)        # $f12 = A[s1][s0]
	li		$v0,  2				# specify print float system call
	syscall						# print A[s1][s0]
	la		$a0,  spaces
	li		$v0,  4				# specify print string system call
	syscall						# print spaces

	addiu	$s2,  $s2, 4		# increment pointer by 4

	addiu	$s0,  $s0, 1        # increment s0
	blt		$s0,  $a1, loop_s0  # loop while s0 < a1
	nop
	la		$a0,  newline
	syscall						# print newline
	addiu	$s1,  $s1, 1		# increment s1
	blt		$s1,  $a1, loop_s1  # loop while s1 < a1
	nop
	la		$a0,  newline
	syscall						# print newline

	lw		$ra,  16($sp)
	lw		$s2,  12($sp)
	lw		$s1,  8($sp)
	lw		$s0,  4($sp)
	lw		$a0,  0($sp)		# done restoring registers
	addiu	$sp,  $sp, 20		# remove stack frame

	jr		$ra					# return from subroutine
	nop							# this is the delay slot associated with all types of jumps

### End of text segment

### Data segment 
	.data
	
### String constants
spaces:
	.asciiz "   "   			# spaces to insert between numbers
newline:
	.asciiz "\n"  				# newline

## Input matrix: (4x4) ##
.include	"matrix_4x4.s"

## Input matrix: (24x24) ##
.include	"matrix_24x24.s"
