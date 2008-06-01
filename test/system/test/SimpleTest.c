#include "unity.h"
#include "Simple.h"

#include <setjmp.h>
#include <stdio.h>

jmp_buf AbortFrame;


void setUp(void)
{
}

void tearDown(void)
{
}

void test_Simple_Add_ShouldSumValues(void)
{
    TEST_ASSERT_EQUAL(  5, Add(  2, 3));
    TEST_ASSERT_EQUAL(  5, Add(  1, 4));
    TEST_ASSERT_EQUAL(  5, Add( -2, 7));
    TEST_ASSERT_EQUAL(100, Add( 25, 75));
    TEST_ASSERT_EQUAL(-10, Add(-90, 80));
}


static void runTest(UnityTestFunction test)
{
    if (TEST_PROTECT())
    {
        test();
    }
}


int main(void)
{
    Unity.TestFile = "SimpleTest.c";
    UnityBegin();

    // RUN_TEST calls runTest
    RUN_TEST(test_Simple_Add_ShouldSumValues);

    UnityEnd();
    
    return 0;
}

