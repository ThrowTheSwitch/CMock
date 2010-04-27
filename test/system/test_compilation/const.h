/* ==========================================
    CMock Project - Automatic Mock Generation for C
    Copyright (c) 2007 Mike Karlesky, Mark VanderVoord, Greg Williams
    [Released under MIT License. Please refer to license.txt for details]
========================================== */

struct _DUMMY_T { unsigned int a; float b; };

void const_variants1( const char* a, int const, unsigned short const * c );

void const_variants2( 
	struct _DUMMY_T const * const param1,
	const unsigned long int const * const param2,
	const struct _DUMMY_T const * param3 ); 

