### Text segment
	.text
start:
	la		$a0, matrix_4x4		# a0 = A (base address of matrix)
	li		$a1, 4    		    # a1 = N (number of elements per row)
	li		$a2, 1				# a2 = B
	
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
	#l.s		$f0, _0f
	#addu	$t0, $a0, $a1
	#s.s		$f0, ($t0)


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
div		_N, _B
mflo	_M


.eqv	_I	$t8
.eqv	_J	$t9
.eqv	_block_row_max $s1
.eqv	_block_col_max $s2
.eqv	_k  $t7
.eqv	_j	$t6
.eqv	_i	$t5
.eqv	_pivot_max $t4
.eqv	_A_kk $t1
.eqv	_A_kj $t0

.eqv	_A_ij $t2
.eqv	_A_ik $t1
.eqv	_A_kj $t0

.eqv	_max_kJ $t3
.eqv	_kN		$s3
.eqv	_iN		$s4

# for all block rows
	move	_I, $zero
loop_block_rows:
	addu	_block_row_max, _I, _M
	addu	_block_row_max, _block_row_max, -1

	

# for all block columns
	move	_J, $zero
loop_block_cols:
	addu	_block_col_max, _J, _M
	addu	_block_col_max, _block_col_max, -1

# loop over pivot elements
	move	_k, $zero
# Min
	move	_pivot_max, _block_row_max
	ble		_block_row_max, _block_col_max, loop_pivot_elems
	nop
	move	_pivot_max, _block_col_max


# loop over pivot elements
	move	_kN, _k
loop_pivot_elems:
	addu 	_max_kJ, _k, 1
	bge		_max_kJ, _J, end_max
	nop
	move	_max_kJ, _J
end_max:
	move	_j, _max_kJ

	
	

# if pivot element within block
if_elem_in_block:
	blt		_k, _I, loop_below_pivot_row
	nop
	bgt		_k, _block_row_max, loop_below_pivot_row
	nop

	

# perform calculations on pivot
	# A[k][k]
	addu	_A_kk, _kN, _k
	sll		_A_kk, _A_kk, 2
	addu	_A_kk, _A_kk, _A


loop_calc:
	# A[k][j]
	addu	_A_kj, _kN, _j
	sll		_A_kj, _A_kj, 2
	addu	_A_kj, _A_kj, _A

	l.s		$f0, (_A_kj)
	nop
	l.s		$f1, (_A_kk)
	nop

	div.s	$f0, $f0, $f1
	s.s		$f0, (_A_kj)

end_loop_calc:
	addiu	_j, _j, 1
	nop
	ble		_j, _block_col_max, loop_calc
	nop
	





# if last element in row
if_elem_last:




	#subu	$s3, _N, 2
	nop
	bne		_j, _N, not_elem_last
	nop
	l.s		$f0, _1f
	nop
	s.s		$f0, (_A_kk)
not_elem_last:


# for all rows below pivot row within block
# Max
	addu	_i, _k, 1
	bge		_i, _I, end_max_0
	nop
	move	_i, _I
	nop
end_max_0:

# iN
	mulu	_iN, _i, _N
	
loop_below_pivot_row:
	# A[i][k]
	#mulu	_A_ik, _i, _N
	addu	_A_ik, _iN, _k
	sll		_A_ik, _A_ik, 2
	addu	_A_ik, _A_ik, _A
	
	move	_j, _max_kJ

loop_block_row:


	# A[k][j]
	#mulu	_A_kj, _k, _N
	addu	_A_kj, _kN, _j
	sll		_A_kj, _A_kj, 2
	addu	_A_kj, _A_kj, _A

	# A[i][j]
	#mulu	_A_ij, _i, _N
	addu	_A_ij, _iN, _j
	sll		_A_ij, _A_ij, 2
	addu	_A_ij, _A_ij, _A

	l.s		$f0, (_A_ij)
	nop
	l.s		$f1, (_A_ik)
	nop
	l.s		$f2, (_A_kj)
	nop

	mul.s	$f1, $f1, $f2
	nop
	sub.s	$f0, $f0, $f1

	s.s		$f0, (_A_ij)

end_loop_block_row:
	addiu	_j, _j, 1
	nop
	ble		_j, _block_col_max, loop_block_row
	nop

# if last element in row
	bne		_j, _N, end_loop_below_pivot_row
	nop
	l.s		$f5, _0f
	s.s		$f5, (_A_ik)

end_loop_below_pivot_row:
	addiu	_i, _i, 1
	addu	_iN, _iN, _N
	nop
	ble		_i, _block_row_max, loop_below_pivot_row
	nop

end_loop_pivot_elems:
	addiu	_k, _k, 1
	addu	_kN, _kN, _N
	nop
	ble		_k, _pivot_max, loop_pivot_elems
	nop

end_loop_block_cols:
	addu	_J, _J, _M
	blt		_J, _N, loop_block_cols
	nop
	
end_loop_block_rows:
	addu	_I, _I, _M
	blt		_I, _N, loop_block_rows
	nop

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
