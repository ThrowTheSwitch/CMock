/* =========================================================================
    CMock - Automatic Mock Generation for C
    ThrowTheSwitch.org
    Copyright (c) 2007-26 Mike Karlesky, Mark VanderVoord, & Greg Williams
    SPDX-License-Identifier: MIT
========================================================================= */

#include "Types.h"
#include "TimerInterruptConfigurator.h"
#include "TimerInterruptHandler.h"

static inline void SetInterruptHandler(void);
static inline void ConfigureInterruptSourceModeRegister(void);
static inline void ClearInterrupt(void);
static inline void EnableCompareInterruptForRegisterC(void);

void Timer_DisableInterrupt(void)
{
  AT91C_BASE_AIC->AIC_IDCR = TIMER0_ID_MASK;
}

void Timer_ResetSystemTime(void)
{
  Timer_SetSystemTime(0);
}

void Timer_ConfigureInterrupt(void)
{
  SetInterruptHandler();
  ConfigureInterruptSourceModeRegister();
  ClearInterrupt();
  EnableCompareInterruptForRegisterC();
}

void Timer_EnableInterrupt(void)
{
  AT91C_BASE_AIC->AIC_IECR = TIMER0_ID_MASK;
}

//
// Helpers
//

static inline void SetInterruptHandler(void)
{
  /* Assigning a function pointer to a void* interrupt vector register is
   * intentional embedded hardware code; suppress the pedantic warning. */
#ifdef __GNUC__
#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wpedantic"
#endif
  AT91C_BASE_AIC->AIC_SVR[AT91C_ID_TC0] = Timer_InterruptHandler;
#ifdef __GNUC__
#pragma GCC diagnostic pop
#endif
}

static inline void ConfigureInterruptSourceModeRegister(void)
{
  AT91C_BASE_AIC->AIC_SMR[AT91C_ID_TC0] = 1;
}

static inline void ClearInterrupt(void)
{
  AT91C_BASE_AIC->AIC_ICCR = TIMER0_ID_MASK;
}

static inline void EnableCompareInterruptForRegisterC(void)
{
  AT91C_BASE_TC0->TC_IER = AT91C_TC_CPCS;
}
