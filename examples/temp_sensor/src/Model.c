/* =========================================================================
    CMock - Automatic Mock Generation for C
    ThrowTheSwitch.org
    Copyright (c) 2007-25 Mike Karlesky, Mark VanderVoord, & Greg Williams
    SPDX-License-Identifier: MIT
========================================================================= */

#include "Model.h"
#include "TaskScheduler.h"
#include "TemperatureFilter.h"

void Model_Init(void)
{
  TaskScheduler_Init();
  TemperatureFilter_Init();
}

