/* ==========================================
    CMock Project - Automatic Mock Generation for C
    Copyright (c) 2007 Mike Karlesky, Mark VanderVoord, Greg Williams
    [Released under MIT License. Please refer to license.txt for details]
========================================== */

#ifndef CMOCK_FRAMEWORK_INTERNALS_H
#define CMOCK_FRAMEWORK_INTERNALS_H

#include "cmock.h"

//define CMOCK_MEM_DYNAMIC to grab memory as needed with malloc
//when you do that, CMOCK_MEM_SIZE is used for incremental size instead of total
#ifdef CMOCK_MEM_STATIC
#undef CMOCK_MEM_DYNAMIC
#endif

#ifdef CMOCK_MEM_DYNAMIC
#include <stdlib.h>
#endif

//this is used internally during pointer arithmetic. make sure this type is the same size as the target's pointer type
#ifndef CMOCK_MEM_PTR_AS_INT
#define CMOCK_MEM_PTR_AS_INT unsigned long
#endif

//0 for no alignment, 1 for 16-bit, 2 for 32-bit, 3 for 64-bit
#ifndef CMOCK_MEM_ALIGN
#define CMOCK_MEM_ALIGN (2)
#endif

//amount of memory to allow cmock to use in its internal heap
#ifndef CMOCK_MEM_SIZE
#define CMOCK_MEM_SIZE (32768)
#endif

//automatically calculated defs for easier reading
#define CMOCK_MEM_ALIGN_SIZE  (1u << CMOCK_MEM_ALIGN)
#define CMOCK_MEM_ALIGN_MASK  (CMOCK_MEM_ALIGN_SIZE - 1)
#define CMOCK_MEM_INDEX_SIZE  (CMOCK_MEM_PTR_AS_INT)((sizeof(CMOCK_MEM_INDEX_TYPE) > CMOCK_MEM_ALIGN_SIZE) ? sizeof(CMOCK_MEM_INDEX_TYPE) : CMOCK_MEM_ALIGN_SIZE)


#endif //CMOCK_FRAMEWORK_INTERNALS
