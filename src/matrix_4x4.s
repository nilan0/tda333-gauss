matrix_4x4:	
	.float 57.0
	.float 20.0
	.float 34.0
	.float 59.0
	
	.float 104.0
	.float 19.0
	.float 77.0
	.float 25.0
	
	.float 55.0
	.float 14.0
	.float 10.0
	.float 43.0
	
	.float 31.0
	.float 41.0
	.float 108.0
	.float 59.0
	
	# These make it easy to check if 
	# data outside the matrix is overwritten
	.word 0xdeadbeef
	.word 0xdeadbeef
	.word 0xdeadbeef
	.word 0xdeadbeef
	.word 0xdeadbeef
	.word 0xdeadbeef
	.word 0xdeadbeef
	.word 0xdeadbeef