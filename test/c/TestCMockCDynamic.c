/* ==========================================
    CMock Project - Automatic Mock Generation for C
    Copyright (c) 2007 Mike Karlesky, Mark VanderVoord, Greg Williams
    [Released under MIT License. Please refer to license.txt for details]
========================================== */

#include "unity.h"
#include "cmock.h"

#define TEST_MEM_INDEX_SIZE  (sizeof(CMOCK_MEM_INDEX_TYPE)) 
#define TEST_MEM_INDEX_PAD   ((sizeof(CMOCK_MEM_INDEX_TYPE) + 3) & ~3) //round up to nearest 4 byte boundary

unsigned int StartingSize;

void setUp(void)
{
  CMock_Guts_MemFreeAll();
  StartingSize = CMock_Guts_MemBytesFree();
  TEST_ASSERT_EQUAL(0, CMock_Guts_MemBytesUsed());
}

void tearDown(void)
{
}

void test_MemNewWillReturnNullIfGivenIllegalSizes(void)
{
  TEST_ASSERT_NULL( CMock_Guts_MemNew(0) );

  //verify we're cleared still
  TEST_ASSERT_EQUAL(0, CMock_Guts_MemBytesUsed());
  TEST_ASSERT_EQUAL(0, CMock_Guts_MemBytesFree());
}

void test_MemNewWillNowSupportSizesGreaterThanTheDefinesCMockSize(void)
{
    TEST_ASSERT_EQUAL(0, CMock_Guts_MemBytesFree());
	
    TEST_ASSERT_NOT_NULL(CMock_Guts_MemNew(CMOCK_MEM_SIZE - TEST_MEM_INDEX_SIZE + 1) );

    TEST_ASSERT_EQUAL(CMOCK_MEM_SIZE + TEST_MEM_INDEX_PAD, CMock_Guts_MemBytesUsed());
    TEST_ASSERT_EQUAL(CMOCK_MEM_SIZE, CMock_Guts_MemBytesFree());
}

void test_MemChainWillReturnNullAndDoNothingIfGivenIllegalInformation(void)
{
  unsigned int* next = CMock_Guts_MemNew(4);
  TEST_ASSERT_EQUAL(4 + TEST_MEM_INDEX_PAD, CMock_Guts_MemBytesUsed());
  TEST_ASSERT_EQUAL(StartingSize - 4 - TEST_MEM_INDEX_PAD, CMock_Guts_MemBytesFree());

  TEST_ASSERT_NULL( CMock_Guts_MemChain((void*)((unsigned int)next + CMOCK_MEM_SIZE), next) );
  TEST_ASSERT_NULL( CMock_Guts_MemChain(next, (void*)((unsigned int)next + CMOCK_MEM_SIZE)) );

  //verify we're still the same
  TEST_ASSERT_EQUAL(4 + TEST_MEM_INDEX_PAD, CMock_Guts_MemBytesUsed());
  TEST_ASSERT_EQUAL(StartingSize - 4 - TEST_MEM_INDEX_PAD, CMock_Guts_MemBytesFree());
}

void test_MemNextWillReturnNullIfGivenABadRoot(void)
{
  TEST_ASSERT_NULL( CMock_Guts_MemNext(NULL) );
  TEST_ASSERT_NULL( CMock_Guts_MemNext((void*)2) );
  TEST_ASSERT_NULL( CMock_Guts_MemNext((void*)0xFFFFFFFE) );

  //verify we're cleared still
  TEST_ASSERT_EQUAL(0, CMock_Guts_MemBytesUsed());
  TEST_ASSERT_EQUAL(StartingSize, CMock_Guts_MemBytesFree());
}

void test_ThatWeCanClaimAndChainAFewElementsTogether(void)
{
  unsigned int  i;
  unsigned int* first = NULL;
  unsigned int* next;
  unsigned int* element[4];

  //verify we're cleared first
  TEST_ASSERT_EQUAL(0, CMock_Guts_MemBytesUsed());
  TEST_ASSERT_EQUAL(StartingSize, CMock_Guts_MemBytesFree());

  //first element
  element[0] = CMock_Guts_MemNew(sizeof(unsigned int));
  TEST_ASSERT_NOT_NULL(element[0]);
  first = CMock_Guts_MemChain(first, element[0]);
  TEST_ASSERT_EQUAL(element[0], first);
  *element[0] = 0;

  //verify we're using the right amount of memory
  TEST_ASSERT_EQUAL(1 * (TEST_MEM_INDEX_PAD + 4), CMock_Guts_MemBytesUsed());
  TEST_ASSERT_EQUAL(StartingSize - 1 * (TEST_MEM_INDEX_PAD + 4), CMock_Guts_MemBytesFree());

  //second element
  element[1] = CMock_Guts_MemNew(sizeof(unsigned int));
  TEST_ASSERT_NOT_NULL(element[1]);
  TEST_ASSERT_NOT_EQUAL(element[0], element[1]);
  TEST_ASSERT_EQUAL(first, CMock_Guts_MemChain(first, element[1]));
  *element[1] = 1;

  //verify we're using the right amount of memory
  TEST_ASSERT_EQUAL(2 * (TEST_MEM_INDEX_PAD + 4), CMock_Guts_MemBytesUsed());
  TEST_ASSERT_EQUAL(StartingSize - 2 * (TEST_MEM_INDEX_PAD + 4), CMock_Guts_MemBytesFree());

  //third element
  element[2] = CMock_Guts_MemNew(sizeof(unsigned int));
  TEST_ASSERT_NOT_NULL(element[2]);
  TEST_ASSERT_NOT_EQUAL(element[0], element[2]);
  TEST_ASSERT_NOT_EQUAL(element[1], element[2]);
  TEST_ASSERT_EQUAL(first, CMock_Guts_MemChain(first, element[2]));
  *element[2] = 2;

  //verify we're using the right amount of memory
  TEST_ASSERT_EQUAL(3 * (TEST_MEM_INDEX_PAD + 4), CMock_Guts_MemBytesUsed());
  TEST_ASSERT_EQUAL(StartingSize - 3 * (TEST_MEM_INDEX_PAD + 4), CMock_Guts_MemBytesFree());

  //fourth element
  element[3] = CMock_Guts_MemNew(sizeof(unsigned int));
  TEST_ASSERT_NOT_NULL(element[3]);
  TEST_ASSERT_NOT_EQUAL(element[0], element[3]);
  TEST_ASSERT_NOT_EQUAL(element[1], element[3]);
  TEST_ASSERT_NOT_EQUAL(element[2], element[3]);
  TEST_ASSERT_EQUAL(first, CMock_Guts_MemChain(first, element[3]));
  *element[3] = 3;

  //verify we're using the right amount of memory
  TEST_ASSERT_EQUAL(4 * (TEST_MEM_INDEX_PAD + 4), CMock_Guts_MemBytesUsed());
  TEST_ASSERT_EQUAL(StartingSize - 4 * (TEST_MEM_INDEX_PAD + 4), CMock_Guts_MemBytesFree());

  //traverse list
  next = first;
  for (i = 0; i < 4; i++)
  {
    TEST_ASSERT_EQUAL(element[i], next);
    TEST_ASSERT_EQUAL(i, *next);
    next = CMock_Guts_MemNext(next);
  }

  //verify we get a null at the end of the list
  TEST_ASSERT_NULL(next);

  //verify we're using the right amount of memory
  TEST_ASSERT_EQUAL(4 * (TEST_MEM_INDEX_PAD + 4), CMock_Guts_MemBytesUsed());
  TEST_ASSERT_EQUAL(StartingSize - 4 * (TEST_MEM_INDEX_PAD + 4), CMock_Guts_MemBytesFree());

  //Free it all
  CMock_Guts_MemFreeAll();

  //verify we're cleared
  TEST_ASSERT_EQUAL(0, CMock_Guts_MemBytesUsed());
  TEST_ASSERT_EQUAL(StartingSize, CMock_Guts_MemBytesFree());
}

void test_ThatWeCanAskForAllSortsOfSizes(void)
{
  unsigned int  i;
  unsigned int* first = NULL;
  unsigned int* next;
  unsigned int  sizes[10]          = {3, 1, 80, 5,  4, 31, 7,  911, 2, 80};
  unsigned int  sizes_buffered[10] = {8, 8, 84, 12, 8, 36, 12, 916, 8, 84}; //includes counter
  unsigned int  sum = 0;
  unsigned int  cap;

  for (i = 0; i < 10; i++)
  {
    next = CMock_Guts_MemNew(sizes[i]);
    TEST_ASSERT_NOT_NULL(next);

    first = CMock_Guts_MemChain(first, next);
    TEST_ASSERT_NOT_NULL(first);

    sum += sizes_buffered[i];
	cap = (StartingSize > (sum + CMOCK_MEM_SIZE)) ? StartingSize : (sum + CMOCK_MEM_SIZE);
  TEST_ASSERT_EQUAL(sum, CMock_Guts_MemBytesUsed());
	TEST_ASSERT(cap >= CMock_Guts_MemBytesFree());
  }

  //verify we can still walk through the elements allocated
  next = first;
  for (i = 0; i < 10; i++)
  {
    TEST_ASSERT_NOT_NULL(next);
    next = CMock_Guts_MemNext(next);
  }

  //there aren't any after that
  TEST_ASSERT_NULL(next);
}
