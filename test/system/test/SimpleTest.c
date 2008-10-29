#include "unity.h"
#include "Simple.h"
#include "MockStuff.h"

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
    ReportAnswer_Expect(5);
    TEST_ASSERT_EQUAL(  5, Add(  2, 3));
    
    ReportAnswer_Expect(5);
    TEST_ASSERT_EQUAL(  5, Add(  1, 4));
    
    ReportAnswer_Expect(5);
    TEST_ASSERT_EQUAL(  5, Add( -2, 7));
    
    ReportAnswer_Expect(100);
    TEST_ASSERT_EQUAL(100, Add( 25, 75));
    
    ReportAnswer_Expect(-10);
    TEST_ASSERT_EQUAL(-10, Add(-90, 80));
}
