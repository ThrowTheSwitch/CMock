/* ==========================================
    CMock Project - Automatic Mock Generation for C
    Copyright (c) 2007 Mike Karlesky, Mark VanderVoord, Greg Williams
    [Released under MIT License. Please refer to license.txt for details]
========================================== */

#ifndef CMOCK_FRAMEWORK_H
#define CMOCK_FRAMEWORK_H

//should be big enough to index full range of CMOCK_MEM_MAX
#ifndef CMOCK_MEM_INDEX_TYPE
#define CMOCK_MEM_INDEX_TYPE  unsigned int
#endif

#define CMOCK_GUTS_NONE (0)

//-------------------------------------------------------
// Memory API
//-------------------------------------------------------
CMOCK_MEM_INDEX_TYPE  CMock_Guts_MemNew(CMOCK_MEM_INDEX_TYPE size);
CMOCK_MEM_INDEX_TYPE  CMock_Guts_MemChain(CMOCK_MEM_INDEX_TYPE root_index, CMOCK_MEM_INDEX_TYPE obj_index);
CMOCK_MEM_INDEX_TYPE  CMock_Guts_MemNext(CMOCK_MEM_INDEX_TYPE previous_item_index);
CMOCK_MEM_INDEX_TYPE  CMock_Guts_MemEndOfChain(CMOCK_MEM_INDEX_TYPE root_index);

void*                 CMock_Guts_GetAddressFor(CMOCK_MEM_INDEX_TYPE index);

CMOCK_MEM_INDEX_TYPE  CMock_Guts_MemBytesFree(void);
CMOCK_MEM_INDEX_TYPE  CMock_Guts_MemBytesUsed(void);
void                  CMock_Guts_MemFreeAll(void);

#endif //CMOCK_FRAMEWORK
