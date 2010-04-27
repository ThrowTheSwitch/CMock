/* ==========================================
    CMock Project - Automatic Mock Generation for C
    Copyright (c) 2007 Mike Karlesky, Mark VanderVoord, Greg Williams
    [Released under MIT License. Please refer to license.txt for details]
========================================== */

#include "unity.h"
#include <setjmp.h>
#include <stdio.h>

char MessageBuffer[50];

extern void setUp(void);
extern void tearDown(void);

extern void test_MemNewWillReturnNullIfGivenIllegalSizes(void);
extern void test_MemChainWillReturnNullAndDoNothingIfGivenIllegalInformation(void);
extern void test_MemNextWillReturnNullIfGivenABadRoot(void);
extern void test_ThatWeCanClaimAndChainAFewElementsTogether(void);
extern void test_ThatCMockStopsReturningMoreDataWhenItRunsOutOfMemory(void);
extern void test_ThatCMockStopsReturningMoreDataWhenAskForMoreThanItHasLeftEvenIfNotAtExactEnd(void);
extern void test_ThatWeCanAskForAllSortsOfSizes(void);

static void runTest(UnityTestFunction test)
{
  if (TEST_PROTECT())
  {
    setUp();
    test();
  }
  if (TEST_PROTECT())
  {
    tearDown();
  }
}


int main(void)
{
  Unity.TestFile = "TestCMock.c";
  UnityBegin();

  // RUN_TEST calls runTest
  RUN_TEST(test_MemNewWillReturnNullIfGivenIllegalSizes, 15);
  RUN_TEST(test_MemChainWillReturnNullAndDoNothingIfGivenIllegalInformation, 25);
  RUN_TEST(test_MemNextWillReturnNullIfGivenABadRoot, 39);
  RUN_TEST(test_ThatWeCanClaimAndChainAFewElementsTogether, 50);
  RUN_TEST(test_ThatCMockStopsReturningMoreDataWhenItRunsOutOfMemory, 132);
  RUN_TEST(test_ThatCMockStopsReturningMoreDataWhenAskForMoreThanItHasLeftEvenIfNotAtExactEnd, 178);
  RUN_TEST(test_ThatWeCanAskForAllSortsOfSizes, 225);

  UnityEnd();
  return 0;
}
