#include "unity.h"
#include "foo.h"

#include "cmock.h"

void setUp(void)
{
}

void tearDown(void)
{
}

void test_foo_init_should_initialize_multiplier()
{
    foo_init();

    CMOCK_MEM_INDEX_TYPE ndx = CMock_Guts_MemNew(32768);
    void *ptr = CMock_Guts_GetAddressFor(ndx);
    printf("ndx: %u, ptr: %p, \n", ndx, ptr);
    printf("free: %u, used: %u, capacity: %u, \n",
           CMock_Guts_MemBytesFree(), CMock_Guts_MemBytesUsed(), CMock_Guts_MemBytesCapacity());

    TEST_ASSERT_NOT_NULL(ptr);
    TEST_ASSERT_EQUAL(CMock_Guts_MemBytesFree() + CMock_Guts_MemBytesUsed(), CMock_Guts_MemBytesCapacity());
}
