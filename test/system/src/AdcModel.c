#include "Types.h"
#include "AdcModel.h"
#include "TaskScheduler.h"
#include "TemperatureCalculator.h"
#include "TemperatureFilter.h"

bool AdcModel_DoGetSample(void)
{
  return TaskScheduler_DoAdc();
}

void AdcModel_ProcessInput(uint16 millivolts)
{
  TemperatureFilter_ProcessInput(TemperatureCalculator_Calculate(millivolts));
}

