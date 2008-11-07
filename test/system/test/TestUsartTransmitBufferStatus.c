#include "unity.h"
#include "Types.h"
#include "UsartTransmitBufferStatus.h"

AT91S_USART UsartPeripheral;

void setUp(void)
{
}

void tearDown(void)
{
}

void testReadyToTransmitShouldReturnStatusPerTransmitBufferReadyStatus(void)
{
  USART_BASE->US_CSR = 0;
  TEST_ASSERT(!Usart_ReadyToTransmit());
  
  USART_BASE->US_CSR = AT91C_US_TXRDY;
  TEST_ASSERT(Usart_ReadyToTransmit());
}
