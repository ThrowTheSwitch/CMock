#ifndef _MYTYPES_H_
#define _MYTYPES_H_

#include <AT91SAM7X256.h>

#ifndef __monitor
#define __monitor
#endif

// Peripheral Helper Definitions

//#define USART_DEBUG
#define USART_0

// Debug USART
#ifdef USART_DEBUG
#define USART_CLOCK_ENABLE  (AT91C_ID_SYS)
#define USART_TX_PIN        (AT91C_PA28_DTXD)
#ifdef TEST
extern AT91S_USART UsartPeripheral;
#define USART_BASE          ((AT91PS_USART)     &UsartPeripheral)
#else
#define USART_BASE          ((AT91PS_USART)     AT91C_BASE_DBGU)
#endif // TEST
#endif // USART_DEBUG


// USART 0
#ifdef USART_0
#define USART_CLOCK_ENABLE  (AT91C_ID_US0)
#define USART_TX_PIN        (AT91C_PA1_TXD0)
#ifdef TEST
extern AT91S_USART UsartPeripheral;
#define USART_BASE          ((AT91PS_USART)     &UsartPeripheral)
#else
#define USART_BASE          ((AT91PS_USART)     AT91C_BASE_US0)
#endif // TEST
#endif // USART_0


// Timer/Counter 0
#define TIMER0_CLOCK_ENABLE (((uint32)0x1) << AT91C_ID_TC0)
#ifdef TEST
extern AT91S_TC Timer0Peripheral;
#define TIMER0_BASE         ((AT91PS_TC)        &Timer0Peripheral)
#else
#define TIMER0_BASE         ((AT91PS_TC)        AT91C_BASE_TC0)
#endif // TEST


// Parallel I/O Bank A
#define PIOA_CLOCK_ENABLE   (((uint32)0x1) << AT91C_ID_PIOA)
#ifdef TEST
extern AT91S_PIO PioAPeripheral;
#define PIOA_BASE           ((AT91PS_PIO)       &PioAPeripheral)
#else
#define PIOA_BASE           ((AT91PS_PIO)       AT91C_BASE_PIOA)
#endif // TEST


// Parallel I/O Bank B
#define PIOB_CLOCK_ENABLE   (((uint32)0x1) << AT91C_ID_PIOB)
#ifdef TEST
extern AT91S_PIO PioBPeripheral;
#define PIOB_BASE           ((AT91PS_PIO)       &PioBPeripheral)
#else
#define PIOB_BASE           ((AT91PS_PIO)       AT91C_BASE_PIOB)
#endif // TEST

// Timer/Counter Output Pin Assignment
#define TIOA0_PIN_MASK      (((uint32)0x1) << 23)


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
