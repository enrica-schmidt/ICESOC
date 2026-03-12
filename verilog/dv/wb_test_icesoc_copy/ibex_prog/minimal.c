#include <stdint.h>

// TODO: Check the address, in the caravel firmware the addresses had to be
// divided by 4 so it's also done here.
#define SRAM_2_LAST_ADDRESS (*(volatile uint32_t *)0x13F)

int main() {

  // Just write a single test word into the second SRAM
  volatile uint32_t *tohost = (uint32_t *)&SRAM_2_LAST_ADDRESS;
  *tohost = 0XCAFEBABE;

  return 0;
}
