/*
 * SPDX-FileCopyrightText: 2020 Efabless Corporation
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 * SPDX-License-Identifier: Apache-2.0
 */

#include "load_mem.h"
#include <defs.h>
#include <gpio_config_io.h>
#include <stdint.h>
#include <stub.c>
/*
        Wishbone Test:
                - Configures MPRJ lower 8-IO pins as outputs
                - Checks counter value through the wishbone port
*/
#define SRAM_2_OFFSET 0x100                    // 0x400 / 4
#define SRAM_LAST_ACCESSIBLE_WORD_ADDRESS 0x3F // 0FF / 4
#define PROGRAM_START_ADDRESS 0x20             // 0x80 / 4

void main() {

  /*
  IO Control Registers
  | DM     | VTRIP | SLOW  | AN_POL | AN_SEL | AN_EN | MOD_SEL | INP_DIS | HOLDH
  | OEB_N | MGMT_EN | | 3-bits | 1-bit | 1-bit | 1-bit  | 1-bit  | 1-bit | 1-bit
  | 1-bit   | 1-bit | 1-bit | 1-bit   | Output: 0000_0110_0000_1110  (0x1808) =
  GPIO_MODE_USER_STD_OUTPUT | DM     | VTRIP | SLOW  | AN_POL | AN_SEL | AN_EN |
  MOD_SEL | INP_DIS | HOLDH | OEB_N | MGMT_EN | | 110    | 0     | 0     | 0 | 0
  | 0     | 0       | 1       | 0     | 0     | 0       |


  Input: 0000_0001_0000_1111 (0x0402) = GPIO_MODE_USER_STD_INPUT_NOPULL
  | DM     | VTRIP | SLOW  | AN_POL | AN_SEL | AN_EN | MOD_SEL | INP_DIS | HOLDH
  | OEB_N | MGMT_EN | | 001    | 0     | 0     | 0      | 0      | 0     | 0 | 0
  | 0     | 1     | 0       |
  */

  /* Set up the housekeeping SPI to be connected internally so	*/
  /* that external pin changes don't affect it.			*/

  reg_wb_enable = 1;
  reg_hkspi_disable = 1;
  // connect to housekeeping SPI

  // Connect the housekeeping SPI to the SPI master
  // so that the CSB line is not left floating.  This allows
  // all of the GPIO pins to be used for user functions.

  reg_mprj_io_37 = GPIO_MODE_MGMT_STD_OUTPUT;
  reg_mprj_io_36 = GPIO_MODE_MGMT_STD_OUTPUT;
  reg_mprj_io_35 = GPIO_MODE_MGMT_STD_OUTPUT;
  reg_mprj_io_34 = GPIO_MODE_MGMT_STD_OUTPUT;
  reg_mprj_io_33 = GPIO_MODE_MGMT_STD_OUTPUT;
  reg_mprj_io_32 = GPIO_MODE_MGMT_STD_OUTPUT;
  reg_mprj_io_31 = GPIO_MODE_MGMT_STD_OUTPUT;
  reg_mprj_io_30 = GPIO_MODE_MGMT_STD_OUTPUT;
  reg_mprj_io_29 = GPIO_MODE_MGMT_STD_OUTPUT;
  reg_mprj_io_28 = GPIO_MODE_MGMT_STD_OUTPUT;
  reg_mprj_io_27 = GPIO_MODE_MGMT_STD_OUTPUT;
  reg_mprj_io_26 = GPIO_MODE_MGMT_STD_OUTPUT;
  reg_mprj_io_25 = GPIO_MODE_MGMT_STD_OUTPUT;
  reg_mprj_io_24 = GPIO_MODE_MGMT_STD_OUTPUT;
  reg_mprj_io_23 = GPIO_MODE_MGMT_STD_OUTPUT;
  reg_mprj_io_22 = GPIO_MODE_MGMT_STD_OUTPUT;
  reg_mprj_io_21 = GPIO_MODE_MGMT_STD_OUTPUT;
  reg_mprj_io_20 = GPIO_MODE_MGMT_STD_OUTPUT;
  reg_mprj_io_19 = GPIO_MODE_MGMT_STD_OUTPUT;
  reg_mprj_io_18 = GPIO_MODE_MGMT_STD_OUTPUT;
  reg_mprj_io_17 = GPIO_MODE_MGMT_STD_OUTPUT;
  reg_mprj_io_16 = GPIO_MODE_MGMT_STD_OUTPUT;

  // Configure lower 8-IOs as user output
  // Observe counter value in the testbench
  reg_mprj_io_0 = GPIO_MODE_MGMT_STD_INPUT_PULLDOWN;
  reg_mprj_io_1 = GPIO_MODE_MGMT_STD_INPUT_PULLDOWN;
  reg_mprj_io_2 = GPIO_MODE_MGMT_STD_INPUT_PULLDOWN;
  reg_mprj_io_3 = GPIO_MODE_MGMT_STD_INPUT_PULLDOWN;
  reg_mprj_io_4 = GPIO_MODE_MGMT_STD_INPUT_PULLDOWN;
  reg_mprj_io_5 = GPIO_MODE_MGMT_STD_INPUT_PULLDOWN;
  reg_mprj_io_6 = GPIO_MODE_MGMT_STD_INPUT_PULLDOWN;
  reg_mprj_io_7 = GPIO_MODE_MGMT_STD_INPUT_PULLDOWN;

  reg_mprj_io_8 = GPIO_MODE_MGMT_STD_INPUT_PULLDOWN;
  reg_mprj_io_9 = GPIO_MODE_MGMT_STD_INPUT_PULLDOWN;
  reg_mprj_io_10 = GPIO_MODE_USER_STD_OUTPUT;
  reg_mprj_io_11 = GPIO_MODE_USER_STD_OUTPUT;
  reg_mprj_io_12 = GPIO_MODE_USER_STD_OUTPUT;

  /* Apply configuration */
  reg_mprj_xfer = 1;
  while (reg_mprj_xfer == 1)
    ;

  // Flag start of the test
  reg_mprj_datal = 0x00010000;
  reg_la2_oenb = reg_la2_iena = 0xFFFFFFFF; // [95:64]

  // Set LA bits 0-3 as outputs
  reg_la0_oenb = reg_la0_oenb & ~0xF;

  // Flag stop ibex_core to program
  reg_mprj_datal = 0x00020000;

  // Set Fetch Enable (bits 1 & 3) to 0
  reg_la0_data = reg_la0_data & ~0xA;

  uint32_t *sram1 = (uint32_t *)&reg_mprj_slave;
  uint32_t *sram2 = (uint32_t *)&reg_mprj_slave + SRAM_2_OFFSET;
  uint32_t sram_write_address;

  // writing data to sram
  uint32_t program_word_index = 0u;
  /*for (uint32_t memory_address = PROGRAM_START_ADDRESS;
       memory_address < PROGRAM_LENGTH + PROGRAM_START_ADDRESS;
       memory_address++) {

    if (memory_address <= SRAM_LAST_ACCESSIBLE_WORD_ADDRESS) {
      sram1[memory_address] = program_data[program_word_index];
    } else {
      sram_write_address = memory_address - SRAM_LAST_ACCESSIBLE_WORD_ADDRESS;
      sram2[sram_write_address] = program_data[program_word_index];
      //asm volatile("addi t0, t0, %[z]\n\t" : [z] "" (&sram2[sram_write_address]));
    }
    reg_mprj_datah = memory_address;
    program_word_index++;
  }*/

  // Flag run ibex_core
  reg_mprj_datal = 0x00030000;
  reg_la0_data = reg_la0_data | 0xA;

  volatile uint32_t tmp;
  for (uint32_t address = 0u; address < SRAM_LAST_ACCESSIBLE_WORD_ADDRESS;
       address++) {
    tmp = sram2[address];
  }

  while (1) {
    if (sram1[4] == 0xDEADBEEF) {
      reg_mprj_datal = 0x00040000; // simulation end with successful test
    } else if (sram1[4] == 0xCAFEBABE) {
      reg_mprj_datal = 0x00050000; // simulation end with failed test
    } else {
      reg_mprj_datal = 0x00060000; // simulation end with failed test
    }
  }
}
