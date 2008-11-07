#include "Types.h"
#include "UsartTransmitBufferStatus.h"

bool Usart_ReadyToTransmit(void)
{
  return (USART_BASE->US_CSR & AT91C_US_TXRDY) > 0;
}
