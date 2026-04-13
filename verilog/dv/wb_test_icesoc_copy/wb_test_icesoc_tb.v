// SPDX-FileCopyrightText: 2020 Efabless Corporation
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
// SPDX-License-Identifier: Apache-2.0

`default_nettype none

`timescale 1 ns / 1 ps

`include "uprj_netlists.v"
`include "caravel_netlists.v"
`include "spiflash.v"

module wb_test_icesoc_tb;
	reg clock;
	reg RSTB;
	//reg CSB;
	reg power1, power2;
	reg power3, power4;
	integer address;

	wire gpio;
	wire [37:0] mprj_io;
	wire [15:0] checkbits;
	wire [31:0]sram_address;
	wire [5:0]i_counter;

	logic rxd_uart_to_mem;
	integer word_idx, fd;
	//logic dummy_signal_debug;

	assign checkbits = mprj_io[31:16];
	assign sram_address = mprj_io[31:0];
	assign i_counter = mprj_io[37:32];

	assign mprj_io[9] = rxd_uart_to_mem;

	//assign mprj_io[3] = (CSB == 1'b1) ? 1'b1 : 1'bz;


	// External clock is used by default.  Make this artificially fast for the
	// simulation.  Normally this would be a slow clock and the digital PLL
	// would be the fast clock.

	always #(CLK_PER/2) clock <= (clock === 1'b0);

	initial begin
		clock = 0;
	end

	localparam CLK_PER = 2 * 12.5;
    localparam MAX_BITBYTES = 2000; //change this back to 20000
    localparam NUM_INSTR = 64; //nr of instructions to be written to sram 
    localparam MEM_BYTES = NUM_INSTR * 4; //4 bytes written per instruction
    localparam BIT_PERIOD_UART_TO_MEM = 8 * CLK_PER;
	
	localparam PAGE_SIZE_BITSTR = 256; //nr words per page, only 1/4th is addressable
	localparam NUM_PAGES_BITSTR = 2; //nr of pages
	
	localparam PAGE_SIZE_INSTRS = 256; //nr words per page, only 1/4th is addressable
	localparam NUM_PAGES_INSTRS = 2; //nr of pages

    reg [7:0] memory[0:MEM_BYTES-1];
	reg [7:0] bitstream[0:MAX_BITBYTES-1];
	reg [7:0] ctrl_bytes[0:2];
	reg [24:0] flat_ctrl_bytes, flat_ctrl_bytes_start;
	reg [31:0] word;

	integer ctrl_byte_idx, bit_idx, data_byte_idx, word_ctr, page_ctr, page_idx;
	reg [7:0] send_byte;


	initial begin
		$dumpfile("wb_test_icesoc.vcd");
		$dumpvars(0, wb_test_icesoc_tb);
		for (address = 0; address < 1024; address = address + 1) begin
			$dumpvars(0, wb_test_icesoc_tb.uut.chip_core.mprj.inst_eFPGA_CPU_top.icesoc_top_i.sram_1_i.mem[address]);
			$dumpvars(0, wb_test_icesoc_tb.uut.chip_core.mprj.inst_eFPGA_CPU_top.icesoc_top_i.sram_2_i.mem[address]);
		end
		/*for (address = 0; address < MEM_BYTES; address = address + 1) begin
			$dumpvars(0, wb_test_icesoc_tb.memory[address]);
		end
		*/

		fd = $fopen("memory.hex", "r");
		if (fd != 0) begin
			$readmemh("memory.hex", memory);
			$display("Read memory hex from %s", "memory.hex");
		end else begin
			$display("\nFailed to open the mem file %s", "memory.hex");
			$fatal;
		end

		fd = $fopen("bitstream.hex", "r");
		if (fd != 0) begin
			$readmemh("bitstream.hex", bitstream);
			$display("Read bitstream hex from %s", "bitstream.hex");
		end else begin
			$display("\nFailed to open the bitstream file %s", "bitstream.hex");
			$fatal;
		end

		RSTB <= 1'b0;
		#2000;
		RSTB <= 1'b1;	    	// Release resetB

		//ctrl_bytes[0] = 8'h41;
		//ctrl_bytes[1] = 8'h60; //write to sram1
		//ctrl_bytes[2] = 8'h80; //start writing at addr 80 in sram1
		flat_ctrl_bytes_start = 24'h416080; //swap endianness in word when sending
		//outer loop: for every word that is written to mem
		//MEM_BYTES/4: nr of words to write, PAGE_SIZE/4: nr of words addressable per page 
		$display("Monitor: Start writing instructions to SRAM");
		for (page_ctr = 0; page_ctr < (MEM_BYTES/4)/(PAGE_SIZE_INSTRS/4); page_ctr = page_ctr + 1) begin
			page_idx = page_ctr % NUM_PAGES_INSTRS;
			for (word_idx = 0; word_idx < PAGE_SIZE_INSTRS; word_idx = word_idx + 4) begin
				word = {memory[(page_ctr*PAGE_SIZE_INSTRS) + word_idx], memory[(page_ctr*PAGE_SIZE_INSTRS) + word_idx+1], memory[(page_ctr*PAGE_SIZE_INSTRS) + word_idx+2], memory[(page_ctr*PAGE_SIZE_INSTRS) + word_idx+3]};
				flat_ctrl_bytes = flat_ctrl_bytes_start + (page_idx * PAGE_SIZE_INSTRS) + word_idx;
				uart_to_mem_send_word(flat_ctrl_bytes, word);
			end
			uart_to_mem_send_word(24'h416000, page_idx); //write 0 or 1 to address 0x000 (address 0 in sram1) so the core can check this if the next page is ready
		end
		$display("Monitor: Done writing instructions to SRAM");
		
		uart_to_mem_send_word(24'h416000, 32'h0);
		uart_to_mem_send_word(24'h416004, PAGE_SIZE_INSTRS); //write instr page size to address 0x004
		uart_to_mem_send_word(24'h416008, NUM_PAGES_INSTRS); //write nr of instr pages to address 0x008

		flat_ctrl_bytes_start = 24'h416480; //swap endianness in word when sending
		//outer loop: for every word that is written to mem
		//MEM_BYTES/4: nr of words to write, PAGE_SIZE/4: nr of words addressable per page 
		uart_to_mem_send_word(24'h416400, 32'hdeadbeef); //initialize page counter so it's not undefined
		uart_to_mem_send_word(24'h416404, PAGE_SIZE_BITSTR); //write bitstream page size to address 0x404
		uart_to_mem_send_word(24'h416408, NUM_PAGES_BITSTR); //write nr of bitstream pages to address 0x408
		//uart_to_mem_send_word(24'h41640c, 3);
		uart_to_mem_send_word(24'h41640c, MAX_BITBYTES/4); //write nr of words in bitstream to address 0x40c

		$display("Monitor: Start configuring eFPGA fabric");
		word_ctr = 0;
		//byte_ctr = 0;
		page_ctr = 0;
		RSTB <= 1'b0;
		#2000;
		RSTB <= 1'b1;	    	// Release resetB
		while(word_ctr < MAX_BITBYTES/4) begin
			page_ctr = word_ctr / (PAGE_SIZE_BITSTR/4);
			page_idx = (page_ctr) % NUM_PAGES_INSTRS;
			flat_ctrl_bytes = flat_ctrl_bytes_start + (page_idx * PAGE_SIZE_BITSTR) + ((word_ctr % (PAGE_SIZE_BITSTR/4)) * 4);
			//$display("page_idx: %0d, flat_ctrl_bytes_start: %0h, (page_idx * PAGE_SIZE_BITSTR): %0d, ((word_ctr %% (PAGE_SIZE_BITSTR/4)) * 4): %0d, flat_ctrl_byes: %0d", page_idx, flat_ctrl_bytes_start, (page_idx * (PAGE_SIZE_BITSTR/4)), ((word_ctr % (PAGE_SIZE_BITSTR/4)) * 4), flat_ctrl_bytes);
			word = {bitstream[(word_ctr*4)], bitstream[(word_ctr*4) + 1], bitstream[(word_ctr*4) + 2], bitstream[(word_ctr*4) + 3]};
			
			uart_to_mem_send_word(flat_ctrl_bytes, word);

			if ((word_ctr + 1)% (PAGE_SIZE_BITSTR/4) == 0) begin
				$timeformat(-9, 2, " ns", 2);
				$display("Monitor: Sending bitstream page %0d [T=%0t]", page_ctr, $realtime);
				$display("page_idx: %0d, flat_ctrl_byes: %0h, word: %h", page_idx, flat_ctrl_bytes, word);
				uart_to_mem_send_word(24'h416400, page_ctr); //write page counter to address 0x000 (address 0 in sram2) so the core can check this if the next page is ready
			end
			
			word_ctr = word_ctr + 1;
		end
		uart_to_mem_send_word(24'h416400, page_ctr);
		$display("Monitor: Done configuring eFPGA fabric");
		/*for (page_ctr = 0; page_ctr < ((MAX_BITBYTES/4)/(PAGE_SIZE_BITSTR/4) + 1); page_ctr = page_ctr + 1) begin
			$display("Monitor: Sending bitstream page %0d", page_ctr);
			$timeformat(-9, 2, " ns", 2);
    		$display("[T=%0t]", $realtime);
			page_idx = page_ctr % NUM_PAGES_BITSTR;
			for (word_idx = 0; word_idx < PAGE_SIZE_BITSTR; word_idx = word_idx + 4) begin
				while (page_ctr * PAGE_SIZE_BITSTR + word_idx < MAX_BITBYTES/4) 
				begin
					word = {bitstream[(page_ctr*PAGE_SIZE_BITSTR) + word_idx], bitstream[(page_ctr*PAGE_SIZE_BITSTR) + word_idx+1], bitstream[(page_ctr*PAGE_SIZE_BITSTR) + word_idx+2], bitstream[(page_ctr*PAGE_SIZE_BITSTR) + word_idx+3]};
					flat_ctrl_bytes = flat_ctrl_bytes_start + (page_idx * PAGE_SIZE_BITSTR) + word_idx;
					uart_to_mem_send_word(flat_ctrl_bytes, word);
				end
			end
			uart_to_mem_send_word(24'h416400, page_ctr); //write page counter to address 0x000 (address 0 in sram2) so the core can check this if the next page is ready
			if (page_ctr == 0) begin
				RSTB <= 1'b0;
				#2000;
				RSTB <= 1'b1;	    	// Release resetB
			end
		end
		$display("Monitor: Done configuring eFPGA fabric");
		*/
		// Repeat cycles of 1000 clock edges as needed to complete testbench
        repeat (10) begin
			repeat (10000) @(posedge clock);
            $display("+1000 cycles");
		end
		/*
		$display("%c[1;31m",27);
		`ifdef GL
			$display ("Monitor: Timeout, Test Mega-Project WB Port (GL) Failed");
		`else
			$display ("Monitor: Timeout, Test Mega-Project WB Port (RTL) Failed");
		`endif
		$display("%c[0m",27);
		*/
		//#100000;
		$finish;
	end

	//pass 3 ctrl bytes and current word to be sent
	//not using output rx but global variable rxd_uart_to_mem to continuously assign value
	task uart_to_mem_send_word(input [23:0] ctrl, input [31:0] word);
		integer ctrl_byte_idx, bit_idx, data_byte_idx;
		//for each word send three control bytes first (41, 60, addr)
		//swap endianness of ctrl and word (ctrl and word have first byte at highest addr and last byte at lowest addr), want to send first byte (MSB) first
		for (ctrl_byte_idx = 2; ctrl_byte_idx >= 0; ctrl_byte_idx = ctrl_byte_idx - 1) begin
			//send start bit
			rxd_uart_to_mem = 1'b0;
			#BIT_PERIOD_UART_TO_MEM;
			//send ctrl bits
			for (bit_idx = 0; bit_idx < 8; bit_idx = bit_idx + 1) begin
				rxd_uart_to_mem = ctrl[ctrl_byte_idx * 8 + bit_idx];
				#BIT_PERIOD_UART_TO_MEM;
			end
			//send stop bit
			rxd_uart_to_mem = 1'b1;
			#BIT_PERIOD_UART_TO_MEM;
			#(2*BIT_PERIOD_UART_TO_MEM); //wait between the bytes to avoid conflicts with the tx part
		end

		for (data_byte_idx = 3; data_byte_idx >= 0; data_byte_idx = data_byte_idx - 1) begin
			//send start bit
			rxd_uart_to_mem = 1'b0;
			#BIT_PERIOD_UART_TO_MEM;
			//send data bits
			for (bit_idx = 0; bit_idx < 8; bit_idx = bit_idx + 1) begin
				rxd_uart_to_mem = word[data_byte_idx * 8 + bit_idx];
				#BIT_PERIOD_UART_TO_MEM;
			end
			//send stop bit
			rxd_uart_to_mem = 1'b1;
			#BIT_PERIOD_UART_TO_MEM;
			#(2*BIT_PERIOD_UART_TO_MEM); //wait between the bytes to avoid conflicts with the tx part
		end
	endtask

	reg [31:0] checkpoint;
	reg [ 7:0] ibex_ctrl;
	initial begin
		ibex_ctrl = 8'b0000_0110;
	   	wait(checkbits == 16'h0001);
	   	$display("Monitor: MPRJ-Logic WB Started");
	   	wait(checkbits == 16'h0002);
	   	$display("Monitor: Program ibex");
		wait(checkbits == 16'h0003);
	   	$display("Monitor: Start ibex");
		ibex_ctrl = 8'b0010_0110;
		//start and finish bitstream upload
	end

	initial begin
		wait(checkbits == 16'h0004);
		$display ("Monitor: ibex Passed");
		//#7000;
		//#(BIT_PERIOD_UART_TO_MEM * 40000);
		//#(BIT_PERIOD_UART_TO_MEM * 450000);
		//$finish;
	end


	initial begin
		wait(checkbits == 16'h0005);
		$display ("Monitor: ibex Failed");
		#7000;
		#(BIT_PERIOD_UART_TO_MEM * 20000);
		$finish;
	end

	assign mprj_io[7:0] = ibex_ctrl;

	initial begin		// Power-up sequence
		power1 <= 1'b0;
		power2 <= 1'b0;
		power3 <= 1'b0;
		power4 <= 1'b0;
		#100;
		power1 <= 1'b1;
		#100;
		power2 <= 1'b1;
		#100;
		power3 <= 1'b1;
		#100;
		power4 <= 1'b1;
	end

	always @(mprj_io[7:0]) begin
		#1 $display("MPRJ-IO state = %b ", mprj_io[7:0]);
	end

	always @(i_counter) begin
		#1 $display("Counter: %b ", i_counter);
	end

	wire flash_csb;
	wire flash_clk;
	wire flash_io0;
	wire flash_io1;

	wire VDD3V3 = power1;
	wire VDD1V8 = power2;
	wire USER_VDD3V3 = power3;
	wire USER_VDD1V8 = power4;
	wire VSS = 1'b0;
        wire wclock =clock;
	caravel uut (
		.vddio	  (VDD3V3),
		.vssio	  (VSS),
		.vdda	  (VDD3V3),
		.vssa	  (VSS),
		.vccd	  (VDD1V8),
		.vssd	  (VSS),
		.vdda1    (USER_VDD3V3),
		.vdda2    (USER_VDD3V3),
		.vssa1	  (VSS),
		.vssa2	  (VSS),
		.vccd1	  (USER_VDD1V8),
		.vccd2	  (USER_VDD1V8),
		.vssd1	  (VSS),
		.vssd2	  (VSS),
		.clock	  (wclock),
		.gpio     (gpio),
        .mprj_io  (mprj_io),
		.flash_csb(flash_csb),
		.flash_clk(flash_clk),
		.flash_io0(flash_io0),
		.flash_io1(flash_io1),
		.resetb	  (RSTB)
	);

	spiflash #(
                .FILENAME("wb_test_icesoc.hex")
	) spiflash (
		.csb(flash_csb),
		.clk(flash_clk),
		.io0(flash_io0),
		.io1(flash_io1),
		.io2(),			// not used
		.io3()			// not used
	);

endmodule
`default_nettype wire
