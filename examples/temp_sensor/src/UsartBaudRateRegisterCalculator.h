/* =========================================================================
    CMock - Automatic Mock Generation for C
    ThrowTheSwitch.org
    Copyright (c) 2007-25 Mike Karlesky, Mark VanderVoord, & Greg Williams
    SPDX-License-Identifier: MIT
========================================================================= */

#ifndef _USARTBAUDRATEREGISTERCALCULATOR_H
#define _USARTBAUDRATEREGISTERCALCULATOR_H

uint8 UsartModel_CalculateBaudRateRegisterSetting(uint32 masterClock, uint32 baudRate);

#endif // _USARTBAUDRATEREGISTERCALCULATOR_H
