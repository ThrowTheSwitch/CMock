#include "Types.h"
#include "TimerInterruptHandler.h"
#include "TimerInterruptConfigurator.h"

static uint32 systemTime;

__monitor void Timer_SetSystemTime(uint32 time)
{
  systemTime = time;
}

__monitor uint32 Timer_GetSystemTime(void)
{
  return systemTime;
}

void Timer_InterruptHandler(void)
{
  uint32 status = TIMER0_BASE->TC_SR;
  if (status & AT91C_TC_CPCS)
  {
    systemTime += 10;
  }
}

