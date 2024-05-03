### Text segment
	.text
start:
	la		$a0, matrix_4x4		# a0 = A (base address of matrix)
	li		$a1, 4    		    # a1 = N (number of elements per row)
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
#.eqv	M	$v0
.eqv	_matrix	$a0
.eqv	_N	$a1
.eqv	_B	$a2
.eqv	_k  $t7
.eqv	_M	$s0

move	_M, $zero


	move	_I, $zero
loop_block_rows:
	
	move	_J, $zero
loop_block_cols:

# Init loop_pivot
	move	_k, $zero
	
# min(I, J)
	move	$t0, _I
	# BRANCH DELAY SLOT?
	ble		_I, _J, end_min
	move	$t0, _J
end_min:
	addiu	$t0, $t0, 1
	mul		$t0, $t0, _M



loop_pivot_elems:

	
	
less_then:
	

if_elem_in_block:
calc_loop:
end_calc_loop:
if_elem_last:
end_loop_pivot_elem:

end_loop_block_cols:
	blt		_J, _B, loop_block_cols
	addiu	_J, _J, 1
	
end_loop_block_rows:
	blt		_I, _B, loop_block_rows
	addiu	_I, _I, 1
	

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
