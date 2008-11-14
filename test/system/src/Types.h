#ifndef _MYTYPES_H_
#define _MYTYPES_H_

#include "AT91SAM7X256.h"

#ifndef __monitor
#define __monitor
#endif

// Peripheral Helper Definitions
#define USART0_CLOCK_ENABLE (AT91C_ID_US0)
#define USART0_TX_PIN       (AT91C_PA1_TXD0)
#define TIMER0_CLOCK_ENABLE (((uint32)0x1) << AT91C_ID_TC0)
#define PIOA_CLOCK_ENABLE   (((uint32)0x1) << AT91C_ID_PIOA)
#define PIOB_CLOCK_ENABLE   (((uint32)0x1) << AT91C_ID_PIOB)
#define TIOA0_PIN_MASK      (((uint32)0x1) << 23) // Timer/Counter Output Pin

// Application Type Definitions
typedef unsigned int uint32;
typedef int int32;
typedef unsigned short uint16;
typedef short int16;
typedef unsigned char uint8;
typedef char int8;  
typedef char bool;

// Application Special Value Definitions
#ifndef TRUE
#define TRUE      (1)
#endif
#ifndef FALSE
#define FALSE     (0)
#endif
#ifndef NULL
#define NULL      (0)
#endif // NULL
#define DONT_CARE (0)

// MIN/MAX Definitions for Standard Types
#define INT8_MAX 127
#define INT8_MIN (-128)
#define UINT8_MAX 0xFFU
#define UINT8_MIN 0x00U
#define INT16_MAX 32767
#define INT16_MIN (-32768)
#define UINT16_MAX 0xFFFFU
#define UINT16_MIN 0x0000U
#define INT32_MAX 0x7FFFFFFF
#define INT32_MIN (-INT32_MAX - 1)
#define UINT32_MAX 0xFFFFFFFFU
#define UINT32_MIN 0x00000000U

#endif // _MYTYPES_H_
