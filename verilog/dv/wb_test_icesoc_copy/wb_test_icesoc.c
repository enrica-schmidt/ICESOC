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

#include <defs.h>
#include <gpio_config_io.h>
#include <stdint.h>
#include <stub.c>
#include "instr_bitstr_sizes.h"

/*
        Wishbone Test:
                - Configures MPRJ lower 8-IO pins as outputs
                - Checks counter value through the wishbone port
*/

#define SRAM_2_OFFSET 0x100                    // 0x400 / 4
#define SRAM_LAST_ACCESSIBLE_WORD_ADDRESS 0x3F // 0FF / 4
#define PROGRAM_START_ADDRESS 0x20             // 0x80 / 4
#define MAX_BITBYTES (BITSTREAM_WORDS * 4)
#define PAGE_SIZE_BITSTR (BITSTR_WORDS_PER_PAGE * 4) //address range of a page, only 1/4th is addressable
#define PAGE_SIZE_INSTRS (INSTRS_WORDS_PER_PAGE * 4) //address range of a page, only 1/4th is addressable
#define BITSTR_NR_PHYS_PAGES (32 / BITSTR_WORDS_PER_PAGE) //nr of physical pages (the bitstream is paged in the second half of sram1, 32 available words)
#define INSTRS_NR_PHYS_PAGES (64 / INSTRS_WORDS_PER_PAGE) //nr of physical pages (the instructions are put in sram2, which has 64 words available)

#define INSTRS_PAGE_A 9
#define INSTRS_PAGE_B 64
#define INSTRS_PAGE_C 21

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
  reg_mprj_datal = 0x10000000; //low 32 bits of 38 bit signal
  reg_la2_oenb = reg_la2_iena = 0xFFFFFFFF; // [95:64]

  // Set LA bits 0-3 as outputs
  reg_la0_oenb = reg_la0_oenb & ~0xF;

  // Flag stop ibex_core to program
  reg_mprj_datal = 0x20000000;

  // Set Fetch Enable (bits 1 & 3) to 0
  reg_la0_data = reg_la0_data & ~0xA;

  volatile uint32_t *sram1 = (uint32_t *)&reg_mprj_slave;
  volatile uint32_t *sram2 = (uint32_t *)&reg_mprj_slave + SRAM_2_OFFSET;

  // Flag run ibex_core
  //reg_mprj_datal = 0x00030000;
  reg_la0_data = reg_la0_data | 0xA;

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
  uint32_t page_request_idx, word_ctr, page_ctr, page_idx, word_ctr_total;
  uint32_t word;

  sram1[0] = PAGE_SIZE_INSTRS;
  sram1[1] = INSTRS_NR_PHYS_PAGES;  
  sram1[2] = 0x00000000;        //initialize instruction page ready counter (first page will be ready when ibex is started))
  sram1[3] = 0x00000000;        //initialize instruction page request counter
  sram1[4] = PAGE_SIZE_BITSTR;  //highest address - lowest address (nr words * 4)
  sram1[5] = BITSTR_NR_PHYS_PAGES;
  sram1[6] = 0xffffffff;        //initialize bistream page ready counter (first page will be ready when ibex is started)
  sram1[7] = 0xffffffff;        //initialize bitstream page request counter    
  sram1[8] = MAX_BITBYTES/4;    //nr of words in bitstream
  
//writing first instruction page to sram1////////////////////////////////////////////////////////////////////////////
  for (word_ctr = 0; word_ctr < INSTRS_PAGE_A; word_ctr++) {
    word = instructions[word_ctr];
    sram1[32 + word_ctr] = word;
  }

//writing second instruction page to sram2////////////////////////////////////////////////////////////////////////////
  for (word_ctr = 0; word_ctr < INSTRS_PAGE_B; word_ctr++) {
    word = instructions[INSTRS_PAGE_A + word_ctr];
    sram2[0 + word_ctr] = word;
  }
//start ibex core
reg_mprj_datal = 0x30000000;  //signaling that first and second instruction page are ready

//writing bitstream to sram1//////////////////////////////////////////////////////////////////////////////////////////
  word_ctr = 0;
  page_request_idx = sram1[7];
  while (page_request_idx == 0xffffffff) { //0xffffffff: first page not requested yet
    page_request_idx = sram1[7]; //read new value of page request
  } //wait until next page is requested
  while (word_ctr < MAX_BITBYTES/4) {
    page_ctr = word_ctr / (PAGE_SIZE_BITSTR/4);
    page_idx = page_ctr % BITSTR_NR_PHYS_PAGES;

    sram1[32 + (page_idx * (PAGE_SIZE_BITSTR/4)) + (word_ctr % (PAGE_SIZE_BITSTR/4))] = bitstream[word_ctr];

    if ((word_ctr + 1) % (PAGE_SIZE_BITSTR/4) == 0) {
         __asm__ volatile("" ::: "memory"); //to make sure all the writes to sram above are done before continuing, otherwise instructions might be reordered
				sram1[6] = page_ctr;  //bitstream page ready counter
        __asm__ volatile("" ::: "memory");

        page_request_idx = sram1[7];
        while (page_request_idx < (page_ctr + 1)) {
          page_request_idx = sram1[7]; //read new value of page request
        } //wait until next page is requested
  	}
		word_ctr++;
  }
  __asm__ volatile("" ::: "memory");
  sram1[6] = page_ctr;
  __asm__ volatile("" ::: "memory");

//writing permanent page with req_next and paging function to sram1///////////////////////////////////////////////
  page_request_idx = sram1[3];
  while(page_request_idx < 1) {
    page_request_idx = sram1[3]; //read new value of page request
  } //wait until page request >= page 1 
  for (word_ctr = 0; word_ctr < INSTRS_PAGE_C; word_ctr++) {
    word = instructions[INSTRS_PAGE_A + INSTRS_PAGE_B + word_ctr];
    sram1[43 + word_ctr] = word;
  }

//writing remaining instruction pages to sram2//////////////////////////////////////////////////////////////////////
  word_ctr_total = INSTRS_PAGE_A + INSTRS_PAGE_B + INSTRS_PAGE_C; //first three pages were written already
  word_ctr = 0;
  page_request_idx = sram1[3];
  while(page_request_idx < 1) {
    page_request_idx = sram1[3]; //read new value of page request
  } //wait until page request >= page 1 
  while(word_ctr < INSTRUCTION_WORDS) {
    page_ctr = word_ctr / (PAGE_SIZE_INSTRS/4);
    page_idx = page_ctr % INSTRS_NR_PHYS_PAGES;

    sram2[(page_idx * (PAGE_SIZE_INSTRS/4)) + (word_ctr % (PAGE_SIZE_INSTRS/4))] = instructions[word_ctr_total];

    if ((word_ctr + 1)% (PAGE_SIZE_INSTRS/4) == 0) {
      __asm__ volatile("" ::: "memory");
      sram1[2] = page_ctr + 1; //write page counter to address 0x000 (address 0 in sram1) so the core can check this if the next page is ready
      __asm__ volatile("" ::: "memory");

      page_request_idx = sram1[3];
      while (page_request_idx < (page_ctr + 2)) {
        page_request_idx = sram1[3]; //read new value of page request
      } //wait until next page is requested
    }
    word_ctr++;
    word_ctr_total++;
  }
  __asm__ volatile("" ::: "memory");
  sram1[2] = page_ctr + 1;
  __asm__ volatile("" ::: "memory");

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//reg_mprj_datal = 0x00040000;  
reg_mprj_datal = 0x00060000; //set en=1 and rst=1 for top design on fabric (io_out[17] = I_top[0] = rst, io_out[18] = I_top[1] = en)
int delay = 1000;
while (delay > 0) {
  delay--;
}
reg_mprj_datal = 0x00040000; //set en=1 and rst=0 for top design on fabric (io_out[17] = I_top[0] = rst, io_out[18] = I_top[1] = en)
delay = 10000;
while (delay > 0) {
  delay--;
}
while (1) {
    if (sram1[9] == 0xdeadbeef && sram1[10] == 0xdeadbeef && sram1[11] == 0xdeadbeef && sram1[12] == 0xdeadbeef && sram1[13] == 0xdeadbeef) {
      reg_mprj_datal = 0x40000000; // simulation end with successful test
    } else if (sram1[1] == 0xCAFEBABE) {
      reg_mprj_datal = 0x50000000; // simulation end with failed test
    } else {
      reg_mprj_datal = 0x60000000; // simulation end with failed test
    }
  }
}