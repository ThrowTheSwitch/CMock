/* ==========================================
    CMock Project - Automatic Mock Generation for C
    Copyright (c) 2007 Mike Karlesky, Mark VanderVoord, Greg Williams
    [Released under MIT License. Please refer to license.txt for details]
========================================== */

#include "unity.h"
#include "cmock.h"

#define TEST_MEM_INDEX_SIZE  (sizeof(CMOCK_MEM_INDEX_TYPE))

void setUp(void)
{
  CMock_Guts_MemFreeAll();
}

void tearDown(void)
{
}

void test_MemNewWillReturnNullIfGivenIllegalSizes(void)
{
  TEST_ASSERT_NULL( CMock_Guts_MemNew(0) );
  TEST_ASSERT_NULL( CMock_Guts_MemNew(CMOCK_MEM_SIZE - TEST_MEM_INDEX_SIZE + 1) );

  //verify we're cleared still
  TEST_ASSERT_EQUAL(0, CMock_Guts_MemBytesUsed());
  TEST_ASSERT_EQUAL(CMOCK_MEM_SIZE, CMock_Guts_MemBytesFree());
}

void test_MemChainWillReturnNullAndDoNothingIfGivenIllegalInformation(void)
{
  unsigned int* next = CMock_Guts_MemNew(4);
  TEST_ASSERT_EQUAL(4 + TEST_MEM_INDEX_SIZE, CMock_Guts_MemBytesUsed());
  TEST_ASSERT_EQUAL(CMOCK_MEM_SIZE - 4 - TEST_MEM_INDEX_SIZE, CMock_Guts_MemBytesFree());

  TEST_ASSERT_NULL( CMock_Guts_MemChain((void*)((unsigned int)next + CMOCK_MEM_SIZE), next) );
  TEST_ASSERT_NULL( CMock_Guts_MemChain(next, (void*)((unsigned int)next + CMOCK_MEM_SIZE)) );

  //verify we're still the same
  TEST_ASSERT_EQUAL(4 + TEST_MEM_INDEX_SIZE, CMock_Guts_MemBytesUsed());
  TEST_ASSERT_EQUAL(CMOCK_MEM_SIZE - 4 - TEST_MEM_INDEX_SIZE, CMock_Guts_MemBytesFree());
}

void test_MemNextWillReturnNullIfGivenABadRoot(void)
{
  TEST_ASSERT_NULL( CMock_Guts_MemNext(NULL) );
  TEST_ASSERT_NULL( CMock_Guts_MemNext((void*)2) );
  TEST_ASSERT_NULL( CMock_Guts_MemNext((void*)0xFFFFFFFE) );

  //verify we're cleared still
  TEST_ASSERT_EQUAL(0, CMock_Guts_MemBytesUsed());
  TEST_ASSERT_EQUAL(CMOCK_MEM_SIZE, CMock_Guts_MemBytesFree());
}

void test_ThatWeCanClaimAndChainAFewElementsTogether(void)
{
  unsigned int  i;
  unsigned int* first = NULL;
  unsigned int* next;
  unsigned int* element[4];

  //verify we're cleared first
  TEST_ASSERT_EQUAL(0, CMock_Guts_MemBytesUsed());
  TEST_ASSERT_EQUAL(CMOCK_MEM_SIZE, CMock_Guts_MemBytesFree());

  //first element
  element[0] = CMock_Guts_MemNew(sizeof(unsigned int));
  TEST_ASSERT_NOT_NULL(element[0]);
  first = CMock_Guts_MemChain(first, element[0]);
  TEST_ASSERT_EQUAL(element[0], first);
  *element[0] = 0;

  //verify we're using the right amount of memory
  TEST_ASSERT_EQUAL(1 * (TEST_MEM_INDEX_SIZE + 4), CMock_Guts_MemBytesUsed());
  TEST_ASSERT_EQUAL(CMOCK_MEM_SIZE - 1 * (TEST_MEM_INDEX_SIZE + 4), CMock_Guts_MemBytesFree());

  //second element
  element[1] = CMock_Guts_MemNew(sizeof(unsigned int));
  TEST_ASSERT_NOT_NULL(element[1]);
  TEST_ASSERT_NOT_EQUAL(element[0], element[1]);
  TEST_ASSERT_EQUAL(first, CMock_Guts_MemChain(first, element[1]));
  *element[1] = 1;

  //verify we're using the right amount of memory
  TEST_ASSERT_EQUAL(2 * (TEST_MEM_INDEX_SIZE + 4), CMock_Guts_MemBytesUsed());
  TEST_ASSERT_EQUAL(CMOCK_MEM_SIZE - 2 * (TEST_MEM_INDEX_SIZE + 4), CMock_Guts_MemBytesFree());

  //third element
  element[2] = CMock_Guts_MemNew(sizeof(unsigned int));
  TEST_ASSERT_NOT_NULL(element[2]);
  TEST_ASSERT_NOT_EQUAL(element[0], element[2]);
  TEST_ASSERT_NOT_EQUAL(element[1], element[2]);
  TEST_ASSERT_EQUAL(first, CMock_Guts_MemChain(first, element[2]));
  *element[2] = 2;

  //verify we're using the right amount of memory
  TEST_ASSERT_EQUAL(3 * (TEST_MEM_INDEX_SIZE + 4), CMock_Guts_MemBytesUsed());
  TEST_ASSERT_EQUAL(CMOCK_MEM_SIZE - 3 * (TEST_MEM_INDEX_SIZE + 4), CMock_Guts_MemBytesFree());

  //fourth element
  element[3] = CMock_Guts_MemNew(sizeof(unsigned int));
  TEST_ASSERT_NOT_NULL(element[3]);
  TEST_ASSERT_NOT_EQUAL(element[0], element[3]);
  TEST_ASSERT_NOT_EQUAL(element[1], element[3]);
  TEST_ASSERT_NOT_EQUAL(element[2], element[3]);
  TEST_ASSERT_EQUAL(first, CMock_Guts_MemChain(first, element[3]));
  *element[3] = 3;

  //verify we're using the right amount of memory
  TEST_ASSERT_EQUAL(4 * (TEST_MEM_INDEX_SIZE + 4), CMock_Guts_MemBytesUsed());
  TEST_ASSERT_EQUAL(CMOCK_MEM_SIZE - 4 * (TEST_MEM_INDEX_SIZE + 4), CMock_Guts_MemBytesFree());

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
  TEST_ASSERT_EQUAL(4 * (TEST_MEM_INDEX_SIZE + 4), CMock_Guts_MemBytesUsed());
  TEST_ASSERT_EQUAL(CMOCK_MEM_SIZE - 4 * (TEST_MEM_INDEX_SIZE + 4), CMock_Guts_MemBytesFree());

  //Free it all
  CMock_Guts_MemFreeAll();

  //verify we're cleared
  TEST_ASSERT_EQUAL(0, CMock_Guts_MemBytesUsed());
  TEST_ASSERT_EQUAL(CMOCK_MEM_SIZE, CMock_Guts_MemBytesFree());
}

void test_ThatCMockStopsReturningMoreDataWhenItRunsOutOfMemory(void)
{
  unsigned int  i;
  unsigned int* first = NULL;
  unsigned int* next;

  //even though we are asking for one byte, we've told it to align to closest 4 bytes, therefore it will waste a byte each time
  //so each call will use 8 bytes (4 for the index, 1 for the data, and 3 wasted).
  //therefore we can safely allocated total/8 times.
  for (i = 0; i < (CMOCK_MEM_SIZE / 8); i++)
  {
    TEST_ASSERT_EQUAL(i*8, CMock_Guts_MemBytesUsed());
    TEST_ASSERT_EQUAL(CMOCK_MEM_SIZE - i*8, CMock_Guts_MemBytesFree());

    next = CMock_Guts_MemNew(1);
    TEST_ASSERT_NOT_NULL(next);

    first = CMock_Guts_MemChain(first, next);
    TEST_ASSERT_NOT_NULL(first);
  }

  //verify we're at top of memory
  TEST_ASSERT_EQUAL(CMOCK_MEM_SIZE, CMock_Guts_MemBytesUsed());
  TEST_ASSERT_EQUAL(0, CMock_Guts_MemBytesFree());

  //The very next call will return a NULL, and any after that
  TEST_ASSERT_NULL(CMock_Guts_MemNew(1));
  TEST_ASSERT_NULL(CMock_Guts_MemNew(1));
  TEST_ASSERT_NULL(CMock_Guts_MemNew(1));

  //verify nothing has changed
  TEST_ASSERT_EQUAL(CMOCK_MEM_SIZE, CMock_Guts_MemBytesUsed());
  TEST_ASSERT_EQUAL(0, CMock_Guts_MemBytesFree());

  //verify we can still walk through the elements allocated
  next = first;
  for (i = 0; i < (CMOCK_MEM_SIZE / 8); i++)
  {
    TEST_ASSERT_NOT_NULL(next);
    next = CMock_Guts_MemNext(next);
  }

  //there aren't any after that
  TEST_ASSERT_NULL(next);
}

void test_ThatCMockStopsReturningMoreDataWhenAskForMoreThanItHasLeftEvenIfNotAtExactEnd(void)
{
  unsigned int  i;
  unsigned int* first = NULL;
  unsigned int* next;

  //we're asking for 12 bytes each time now (4 for index, 8 for data).
  //10 requests will give us 120 bytes used, which isn't enough for another 12 bytes if total memory is 128
  for (i = 0; i < 10; i++)
  {
    TEST_ASSERT_EQUAL(i*12, CMock_Guts_MemBytesUsed());
    TEST_ASSERT_EQUAL(CMOCK_MEM_SIZE - i*12, CMock_Guts_MemBytesFree());

    next = CMock_Guts_MemNew(8);
    TEST_ASSERT_NOT_NULL(next);

    first = CMock_Guts_MemChain(first, next);
    TEST_ASSERT_NOT_NULL(first);

    //verify writing data won't screw us up
    *(unsigned int*)next = i;
  }

  //verify we're at top of memory
  TEST_ASSERT_EQUAL(CMOCK_MEM_SIZE - 8, CMock_Guts_MemBytesUsed());
  TEST_ASSERT_EQUAL(8, CMock_Guts_MemBytesFree());

  //The very next call will return a NULL, and any after that
  TEST_ASSERT_NULL(CMock_Guts_MemNew(8));
  TEST_ASSERT_NULL(CMock_Guts_MemNew(5));

  //verify nothing has changed
  TEST_ASSERT_EQUAL(CMOCK_MEM_SIZE - 8, CMock_Guts_MemBytesUsed());
  TEST_ASSERT_EQUAL(8, CMock_Guts_MemBytesFree());

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

void test_ThatWeCanAskForAllSortsOfSizes(void)
{
  unsigned int  i;
  unsigned int* first = NULL;
  unsigned int* next;
  unsigned int  sizes[5] = {3, 1, 80, 5, 4};
  unsigned int  sizes_buffered[5] = {4, 4, 80, 8, 4};
  unsigned int  sum = 0;

  for (i = 0; i < 5; i++)
  {
    next = CMock_Guts_MemNew(sizes[i]);
    TEST_ASSERT_NOT_NULL(next);

    first = CMock_Guts_MemChain(first, next);
    TEST_ASSERT_NOT_NULL(first);

    sum += sizes_buffered[i] + 4;
    TEST_ASSERT_EQUAL(sum, CMock_Guts_MemBytesUsed());
    TEST_ASSERT_EQUAL(CMOCK_MEM_SIZE - sum, CMock_Guts_MemBytesFree());
  }

  //show that we can't ask for too much memory
  TEST_ASSERT_NULL(CMock_Guts_MemNew(12));
  TEST_ASSERT_NULL(CMock_Guts_MemNew(5));

  //but we CAN ask for something that will still fit
  next = CMock_Guts_MemNew(4);
  TEST_ASSERT_NOT_NULL(next);

  first = CMock_Guts_MemChain(first, next);
  TEST_ASSERT_NOT_NULL(first);

  //verify we're used up now
  TEST_ASSERT_EQUAL(CMOCK_MEM_SIZE, CMock_Guts_MemBytesUsed());
  TEST_ASSERT_EQUAL(0, CMock_Guts_MemBytesFree());

  //verify we can still walk through the elements allocated
  next = first;
  for (i = 0; i < 6; i++)
  {
    TEST_ASSERT_NOT_NULL(next);
    next = CMock_Guts_MemNext(next);
  }

  //there aren't any after that
  TEST_ASSERT_NULL(next);
}
