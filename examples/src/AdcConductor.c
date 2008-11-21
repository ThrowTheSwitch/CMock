#include "Types.h"
#include "AdcConductor.h"
#include "AdcModel.h"
#include "AdcHardware.h"

void AdcConductor_Init(void)
{
  AdcHardware_Init();
}

void AdcConductor_Run(void)
{
  if (AdcModel_DoGetSample() && AdcHardware_GetSampleComplete())
  {
    AdcModel_ProcessInput(AdcHardware_GetSample());
    AdcHardware_StartConversion();
  }
}
