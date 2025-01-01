/* =========================================================================
    CMock - Automatic Mock Generation for C
    ThrowTheSwitch.org
    Copyright (c) 2007-25 Mike Karlesky, Mark VanderVoord, & Greg Williams
    SPDX-License-Identifier: MIT
========================================================================= */

#include "Types.h"
#include "TemperatureFilter.h"
#include <math.h>

static bool initialized;
static float temperatureInCelcius;

void TemperatureFilter_Init(void)
{
  initialized = FALSE;
  temperatureInCelcius = -INFINITY;
}

float TemperatureFilter_GetTemperatureInCelcius(void)
{
  return temperatureInCelcius;
}

void TemperatureFilter_ProcessInput(float temperature)
{
  if (!initialized)
  {
    temperatureInCelcius = temperature;
    initialized = TRUE;
  }
  else
  {
    if (temperature == +INFINITY ||
        temperature == -INFINITY ||
        temperature != temperature)
    {
      /* Check if +/- Infinity or NaN... reset to -Inf in this instance. */
      initialized = FALSE;
      temperatureInCelcius = -INFINITY;
    }
    else
    {
      /* Otherwise apply our low-pass filter to smooth the values */
      temperatureInCelcius = (temperatureInCelcius * 0.75f) + (temperature * 0.25);
    }
  }
}
