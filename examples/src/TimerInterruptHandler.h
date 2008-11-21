#ifndef _TIMERINTERRUPTHANDLER_H
#define _TIMERINTERRUPTHANDLER_H

__monitor void Timer_SetSystemTime(uint32 time);
__monitor uint32 Timer_GetSystemTime(void);
void Timer_InterruptHandler(void);

#endif // _TIMERINTERRUPTHANDLER_H
