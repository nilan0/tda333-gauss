### Text segment
	.text
start:
	la		$a0, matrix_24x24		# a0 = A (base address of matrix)
	li		$a1, 24    		    # a1 = N (number of elements per row)
	li		$a2, 4				# a2 = B
	
								# <debug>
	#jal 	print_matrix	    # print matrix before elimination
	#nop							# </debug>
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
.eqv	_A	$a0

.eqv	_M	$s0
.eqv	_N	$a1
.eqv	_B	$a2
# size of block is (M*M)
divu	_M, _N, _B


.eqv	_I		$t8
.eqv	_J		$t9
.eqv	_block_row_max $s1
.eqv	_block_col_max $s2
.eqv	_k  		$t7
.eqv	_j		$t6
.eqv	_i		$t5
.eqv	_pivot_max 	$t4
.eqv	_A_kk		$t1
.eqv	_A_kj		$t0

.eqv	_A_ij		$t2
.eqv	_A_ik		$t1
.eqv	_A_kj		$t0

.eqv	_max_kJ		$t3
.eqv	_4N		$s5
.eqv	_k4N		$s3
.eqv	_i4N		$s4
.eqv	_4M		$s6 
.eqv	_kN		$s7
l.s	$f9, _0f
l.s	$f8, _1f

	
	sll	_4N, _N, 2
	sll	_4M, _M, 2
	

# for all block rows
	
	move	_I, $zero
	nop	# -2000
	nop
loop_block_rows:
	bge	_I, _4N, end_loop_block_rows
	addu	_block_row_max, _I, _4M
	addu	_block_row_max, _block_row_max, -4

# for all block columns
	move	_J, $zero
	nop
loop_block_cols:
	bge	_J, _4N, end_loop_block_cols
	addu	_block_col_max, _J, _4M
	addu	_block_col_max, _block_col_max, -4

# loop over pivot elements
	move	_k, $zero
# Min
	ble	_block_row_max, _block_col_max, end_min_0
	move	_pivot_max, _block_row_max
	move	_pivot_max, _block_col_max
end_min_0:

# loop over pivot elements
	move	_k4N, _k
loop_pivot_elems:
	bgt	_k, _pivot_max, end_loop_pivot_elems
	nop
	
	addu 	_max_kJ, _k, 4
	bge	_max_kJ, _J, end_max
	nop
	move	_max_kJ, _J
	
	

# if pivot element within block
if_elem_in_block:
	# 178472
	blt	_k, _I, init_loop_below_pivot_row
	nop
	bgt	_k, _block_row_max, init_loop_below_pivot_row
	nop
	
	#blt	_k, _J, end_max
	#move	_max_kJ, _J
	#addu 	_max_kJ, _k, 4
end_max:
	move	_j, _max_kJ
	
# perform calculations on pivot
	# A[k][k]
	
	addu	_A_kk, _k4N, _k
	addu	_A_kk, _A_kk, _A
	l.s	$f1, (_A_kk)
	#nop
	#div.s	$f1, $f8, $f1
	

loop_calc:
	bgt	_j, _block_col_max, end_loop_calc
	
	# A[k][j]
	addu	_A_kj, _k4N, _j
	addu	_A_kj, _A_kj, _A
	l.s	$f0, (_A_kj)
	#mul.s	$f0, $f0, $f1
	div.s	$f0, $f0, $f1
	s.s	$f0, (_A_kj)
	
	b	loop_calc
	addiu	_j, _j, 4
	
end_loop_calc:
	
# if last element in row
if_elem_last:
	bne	_j, _4N, not_elem_last_0
	nop
	s.s	$f8, (_A_kk)
not_elem_last_0:

init_loop_below_pivot_row:
# for all rows below pivot row within block
# Max
	addu	_i, _k, 4
	bge	_i, _I, end_max_0
	nop
	move	_i, _I
end_max_0:

# iN
	mulu	_i4N, _i, _N
loop_below_pivot_row:
	bgt	_i, _block_row_max, end_loop_below_pivot_row

	# A[i][k]
	addu	_A_ik, _i4N, _k
	move	_j, _max_kJ
	addu	_A_ik, _A_ik, _A

loop_block_row:
	bgt	_j, _block_col_max, end_loop_block_row

	# A[k][j]
	addu	_A_kj, _k4N, _j
	addu	_A_kj, _A_kj, _A

	# A[i][j]
	addu	_A_ij, _i4N, _j
	addu	_A_ij, _A_ij, _A

	l.s	$f1, (_A_ik)
	l.s	$f2, (_A_kj)
	l.s	$f0, (_A_ij)

	mul.s	$f1, $f1, $f2
	sub.s	$f0, $f0, $f1

	s.s	$f0, (_A_ij)
	
	b	loop_block_row
	addiu	_j, _j, 4
	
end_loop_block_row:

# if last element in row
	bne	_j, _4N, not_last_elem
	nop
	s.s	$f9, (_A_ik)
not_last_elem:
	
	addiu	_i, _i, 4
	b	loop_below_pivot_row
	addu	_i4N, _i4N, _4N
end_loop_below_pivot_row:
	
	
	addiu	_k, _k, 4
	b	loop_pivot_elems
	addu	_k4N, _k4N, _4N
end_loop_pivot_elems:


	b	loop_block_cols
	addu	_J, _J, _4M
end_loop_block_cols:
	
	b	loop_block_rows
	addu	_I, _I, _4M
end_loop_block_rows:

	lw	$ra, 0($sp)			# done restoring registers
	addiu	$sp, $sp, 4			# remove stack frame

	jr	$ra					# return from subroutine
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
_1f: .float 1.0
_0f: .float 0.0
	
### String constants
spaces:
	.asciiz "   "   			# spaces to insert between numbers
newline:
	.asciiz "\n"  				# newline

## Input matrix: (4x4) ##
.include	"matrix_4x4.s"

## Input matrix: (24x24) ##
.include	"matrix_24x24.s"
