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
extern void test_MemNewWillNowSupportSizesGreaterThanTheDefinesCMockSize(void);
extern void test_MemChainWillReturnNullAndDoNothingIfGivenIllegalInformation(void);
extern void test_MemNextWillReturnNullIfGivenABadRoot(void);
extern void test_ThatWeCanClaimAndChainAFewElementsTogether(void);
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
  Unity.TestFile = "TestCMockDynamic.c";
  UnityBegin();

  // RUN_TEST calls runTest
  RUN_TEST(test_MemNewWillReturnNullIfGivenIllegalSizes, 20);
  RUN_TEST(test_MemNewWillNowSupportSizesGreaterThanTheDefinesCMockSize, 29);
  RUN_TEST(test_MemChainWillReturnNullAndDoNothingIfGivenIllegalInformation, 39);
  RUN_TEST(test_MemNextWillReturnNullIfGivenABadRoot, 53);
  RUN_TEST(test_ThatWeCanClaimAndChainAFewElementsTogether, 64);
  RUN_TEST(test_ThatWeCanAskForAllSortsOfSizes, 146);

  UnityEnd();
  return 0;
}
