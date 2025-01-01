/* =========================================================================
    CMock - Automatic Mock Generation for C
    ThrowTheSwitch.org
    Copyright (c) 2007-25 Mike Karlesky, Mark VanderVoord, & Greg Williams
    SPDX-License-Identifier: MIT
========================================================================= */

#include "unity.h"
#include "foo.h"

void setUp(void)
{
}

void tearDown(void)
{
}

void test_foo_init_should_initialize_multiplier()
{
    foo_init();

    TEST_ASSERT_FALSE(0);
}
