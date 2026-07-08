/* =========================================================================
    CMock - Automatic Mock Generation for C
    ThrowTheSwitch.org
    Copyright (c) 2007-26 Mike Karlesky, Mark VanderVoord, & Greg Williams
    SPDX-License-Identifier: MIT
========================================================================= */

#include "unity.h"
#include "Types.h"
#include "UsartConductor.h"
#include "MockUsartModel.h"
#include "MockUsartHardware.h"
#include "MockTaskScheduler.h"

void setUp(void)
{
}

void tearDown(void)
{
}

void testShouldInitializeHardwareWhenInitCalled(void)
{
  char wakeup[] = "Hey there!";
  UsartModel_GetBaudRateRegisterSetting_ExpectAndReturn(4);
  UsartModel_GetWakeupMessage_ExpectAndReturn(wakeup);
  UsartHardware_TransmitString_Expect(wakeup);
  UsartHardware_Init_Expect(4);

  UsartConductor_Init();
}

void testRunShouldNotDoAnythingIfSchedulerSaysItIsNotTimeYet(void)
{
  TaskScheduler_DoUsart_ExpectAndReturn(FALSE);

  UsartConductor_Run();
}

void testRunShouldGetCurrentTemperatureAndTransmitIfSchedulerSaysItIsTime(void)
{
  char temperature[] = "hey there";
  TaskScheduler_DoUsart_ExpectAndReturn(TRUE);
  UsartModel_GetFormattedTemperature_ExpectAndReturn(temperature);
  UsartHardware_TransmitString_Expect(temperature);

  UsartConductor_Run();
}
