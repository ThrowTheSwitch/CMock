#ifndef CMOCK_FRAMEWORK_H
#define CMOCK_FRAMEWORK_H

//-------------------------------------------------------
// Memory API
//-------------------------------------------------------
void*         CMock_Guts_MemNew(unsigned int size);
void*         CMock_Guts_MemChain(void* root, void* obj);
void*         CMock_Guts_MemNext(void* previous_item);
unsigned int  CMock_Guts_MemBytesFree(void);
unsigned int  CMock_Guts_MemBytesUsed(void);
void          CMock_Guts_MemFreeAll(void);

#endif //CMOCK_FRAMEWORK
