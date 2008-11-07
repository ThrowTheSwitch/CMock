#include "unity.h"
#include "Types.h"
#include "UsartConfigurator.h"

AT91S_PIO PioAPeripheral;
AT91S_PMC PmcPeripheral;
AT91S_USART UsartPeripheral;

void setUp(void)
{
}

void tearDown(void)
{
}

void testConfigureUsartIOShouldConfigureUsartTxPinfForPeripheralIO(void)
{
  PIOA_BASE->PIO_ASR = 0;
  PIOA_BASE->PIO_BSR = 0xffffffff;
  PIOA_BASE->PIO_PDR = 0;
  Usart_ConfigureUsartIO();
  TEST_ASSERT_EQUAL(USART_TX_PIN, PIOA_BASE->PIO_ASR);
  TEST_ASSERT_EQUAL(0, PIOA_BASE->PIO_BSR);
  TEST_ASSERT_EQUAL(USART_TX_PIN, PIOA_BASE->PIO_PDR);
}

void testEnablePeripheralClockShouldEnableClockToUsartPeripheral(void)
{
  AT91C_BASE_PMC->PMC_PCER = 0;
  Usart_EnablePeripheralClock();
  TEST_ASSERT_EQUAL(((uint32)1) << USART_CLOCK_ENABLE, AT91C_BASE_PMC->PMC_PCER);
}

void testResetShouldDisableAllUsartInterrupts(void)
{
  USART_BASE->US_IDR = 0;
  Usart_Reset();
  TEST_ASSERT_EQUAL(0xffffffff, USART_BASE->US_IDR);
}

void testResetShouldResetUsartTransmitterAndReceiver(void)
{
  USART_BASE->US_CR = 0;
  Usart_Reset();
  TEST_ASSERT_EQUAL(AT91C_US_RSTRX | AT91C_US_RSTTX | AT91C_US_RXDIS | AT91C_US_TXDIS, USART_BASE->US_CR);
}

void testConfigureModeShouldSetUsartModeToAsynchronous(void)
{
  uint32 asyncMode =  (AT91C_US_USMODE_NORMAL |
                        AT91C_US_NBSTOP_1_BIT |
                        AT91C_US_PAR_NONE |
                        AT91C_US_CHRL_8_BITS |
                        AT91C_US_CLKS_CLOCK);

  USART_BASE->US_MR = ~asyncMode;
  Usart_ConfigureMode();
  TEST_ASSERT_EQUAL(asyncMode, USART_BASE->US_MR);
}

void testSetBaudRateRegisterShouldSetUsartBaudRateRegisterToValuePassedAsParameter(void)
{
  USART_BASE->US_BRGR = 0;
  Usart_SetBaudRateRegister(3);
  TEST_ASSERT_EQUAL(3, USART_BASE->US_BRGR);
  Usart_SetBaudRateRegister(251);
  TEST_ASSERT_EQUAL(251, USART_BASE->US_BRGR);
}


void testEnableShouldEnableUsart0Transmitter(void)
{
  USART_BASE->US_CR = 0;
  Usart_Enable();
  TEST_ASSERT_EQUAL(AT91C_US_TXEN, USART_BASE->US_CR);
}
