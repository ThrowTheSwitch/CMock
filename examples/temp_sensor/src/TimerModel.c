/* =========================================================================
    CMock - Automatic Mock Generation for C
    ThrowTheSwitch.org
    Copyright (c) 2007-25 Mike Karlesky, Mark VanderVoord, & Greg Williams
    SPDX-License-Identifier: MIT
========================================================================= */

#include "Types.h"
#include "TimerModel.h"
#include "TaskScheduler.h"

void TimerModel_UpdateTime(uint32 systemTime)
{
  TaskScheduler_Update(systemTime);
}

