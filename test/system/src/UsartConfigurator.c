#include "Types.h"
#include "UsartConfigurator.h"

void Usart_ConfigureUsartIO(void)
{
  PIOA_BASE->PIO_ASR = USART_TX_PIN;
  PIOA_BASE->PIO_BSR = 0;
  PIOA_BASE->PIO_PDR = USART_TX_PIN;
}

void Usart_EnablePeripheralClock(void)
{
  AT91C_BASE_PMC->PMC_PCER = ((uint32)1) << USART_CLOCK_ENABLE;
}

void Usart_Reset(void)
{
  USART_BASE->US_IDR = 0xffffffff;
  USART_BASE->US_CR = AT91C_US_RSTRX | AT91C_US_RSTTX | AT91C_US_RXDIS | AT91C_US_TXDIS;
}

void Usart_ConfigureMode(void)
{
  USART_BASE->US_MR = AT91C_US_USMODE_NORMAL |
                          AT91C_US_NBSTOP_1_BIT |
                          AT91C_US_PAR_NONE |
                          AT91C_US_CHRL_8_BITS |
                          AT91C_US_CLKS_CLOCK;
}

void Usart_SetBaudRateRegister(uint8 baudRateRegisterSetting)
{
  USART_BASE->US_BRGR = baudRateRegisterSetting;
}

void Usart_Enable(void)
{
  USART_BASE->US_CR = AT91C_US_TXEN;
}
