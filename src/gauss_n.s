### Text segment
	.text
start:
	la		$a0, matrix_24x24		# a0 = A (base address of matrix)
	li		$a1, 24    		    # a1 = N (number of elements per row)
	#li		$a2, 1				# a2 = B
	
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
.eqv	_N	$a1

.eqv	_k  		$s0
.eqv	_j		$s1
.eqv	_i		$s2

.eqv	_A_kk		$t0
.eqv	_A_kj		$t1
.eqv	_A_ij		$t2
.eqv	_A_ik		$t3

.eqv	_k4N		$t4
.eqv	_i4N		$t5
.eqv	_4N		$t6
.eqv	_kN		$t7

.eqv	_0f		$f8
.eqv	_1f		$f9

li	$t0, 0
li	$t1, 0x3f800000
mtc1	$t0, _0f
mtc1	$t1, _1f

sll	_4N, _N, 2
	

	move	_k, $zero
	move	_k4N, _A

# Loop over all diagonal (pivot) elements
loop_pivots:
	bge	_k, _4N, end_loop_pivots	# 4k < 4N
	
	#mulu	_k4N, _k, _N
	#addu	_k4N, _k4N, _A
	
	# A[k][k]
	addu	_A_kk, _k4N, _k
	l.s	$f2, (_A_kk)
	addiu	_j, _k, 4
	div.s	$f2, _1f, $f2
	
	
	

# for all elements in pivot row and right of pivot element
loop_row:
	bge	_j, _4N, end_loop_row
	
		# A[k][j]
		addu	_A_kj, _k4N, _j
		
		l.s	$f0, (_A_kj)
		mul.s	$f0, $f0, $f2
		s.s	$f0, (_A_kj)
	
	b	loop_row
	addiu	_j, _j, 4
end_loop_row:
	s.s	_1f, (_A_kk)

	addu	_i, _k, 4
	mulu	_i4N, _i, _N
	addu	_i4N, _i4N, _A
loop_below:
	bge	_i, _4N, end_loop_below

		# A[i][k]
		addu	_A_ik, _i4N, _k
	
		addu	 _j, _k, 4
loop_right:
		bge	_j, _4N, end_loop_right

			# A[k][j]
			addu	_A_kj, _k4N, _j


			# A[i][j]
			addu	_A_ij, _i4N, _j

			l.s	$f1, (_A_ik)
			l.s	$f2, (_A_kj)
			l.s	$f0, (_A_ij)
	
			mul.s	$f1, $f1, $f2
			sub.s	$f0, $f0, $f1

			s.s	$f0, (_A_ij)
	
		b	loop_right
		addiu	_j, _j, 4
end_loop_right:
		s.s	_0f, (_A_ik)

		addu	_i4N, _i4N, _4N
		b	loop_below
		addiu	_i, _i, 4
end_loop_below:

	addu	_k4N, _k4N, _4N
	b	loop_pivots
	addiu	_k, _k, 4
end_loop_pivots:

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
float1: .float 1.0
float0: .float 0.0
	
### String constants
spaces:
	.asciiz "   "   			# spaces to insert between numbers
newline:
	.asciiz "\n"  				# newline

## Input matrix: (4x4) ##
.include	"matrix_4x4.s"

## Input matrix: (24x24) ##
.include	"matrix_24x24.s"
