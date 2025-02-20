/* =========================================================================
    CMock - Automatic Mock Generation for C
    ThrowTheSwitch.org
    Copyright (c) 2007-25 Mike Karlesky, Mark VanderVoord, & Greg Williams
    SPDX-License-Identifier: MIT
========================================================================= */

#include <stdio.h>
#include "foo.h"

int real_main(int argc, char ** argv)
{
    printf("Hello world!\n");
    return 0;
}

#ifndef TEST
int main(int argc, char ** argv)
{
    return real_main(argc, argv);
}
#endif
