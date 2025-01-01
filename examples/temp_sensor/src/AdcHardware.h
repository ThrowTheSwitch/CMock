/* =========================================================================
    CMock - Automatic Mock Generation for C
    ThrowTheSwitch.org
    Copyright (c) 2007-25 Mike Karlesky, Mark VanderVoord, & Greg Williams
    SPDX-License-Identifier: MIT
========================================================================= */

#ifndef _ADCHARDWARE_H
#define _ADCHARDWARE_H

void AdcHardware_Init(void);
void AdcHardware_StartConversion(void);
bool AdcHardware_GetSampleComplete(void);
uint16 AdcHardware_GetSample(void);

#endif // _ADCHARDWARE_H
