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

bool AdcModel_DoNothingExceptTestASpecialType(EXAMPLE_STRUCT_T ExampleStruct)
{
    //This doesn't really do anything. it's only here to make sure I can compare a struct.
}
