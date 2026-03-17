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

	localparam CLK_PER = 2* 12.5;
    localparam MAX_BITBYTES = 20000;
    localparam NUM_INSTR = 16; //nr of instructions to be written to sram 
    localparam MEM_BYTES = NUM_INSTR * 7; //7 bytes written per instruction (uart to mem write_cmd, address etc))
    localparam BIT_PERIOD_UART_TO_MEM = 8 * CLK_PER;
    reg [7:0] memory[0:MEM_BYTES-1];
	reg [7:0] bitstream[0:MAX_BITBYTES-1];
	reg [7:0] ctrl_bytes[0:2];
	reg [24:0] flat_ctrl_bytes;
	reg [31:0] word;

	integer ctrl_byte_idx, bit_idx, data_byte_idx;
	reg [7:0] send_byte;


	initial begin
		$dumpfile("wb_test_icesoc.vcd");
		$dumpvars(0, wb_test_icesoc_tb);
		for (address = 0; address < 1024; address = address + 1) begin
			$dumpvars(0, wb_test_icesoc_tb.uut.chip_core.mprj.inst_eFPGA_CPU_top.icesoc_top_i.sram_1_i.mem[address]);
			$dumpvars(0, wb_test_icesoc_tb.uut.chip_core.mprj.inst_eFPGA_CPU_top.icesoc_top_i.sram_2_i.mem[address]);
		end
		for (address = 0; address < MEM_BYTES; address = address + 1) begin
			$dumpvars(0, wb_test_icesoc_tb.memory[address]);
		end

		fd = $fopen("uart_to_mem.hex", "r");
		if (fd != 0) begin
			$readmemh("uart_to_mem.hex", memory);
			$display("Read memory hex from %s", "uart_to_mem.hex");
		end else begin
			$display("\nFailed to open the mem file %s", "uart_to_mem.hex");
			$fatal;
		end

		fd = $fopen("top.hex", "r");
		if (fd != 0) begin
			$readmemh("top.hex", bitstream);
			$display("Read bitstream hex from %s", "top.hex");
		end else begin
			$display("\nFailed to open the bitstream file %s", "top.hex");
			$fatal;
		end

		RSTB <= 1'b0;
		#2000;
		RSTB <= 1'b1;	    	// Release resetB
		
		/*dummy_signal_debug = 1'b0;
		#BIT_PERIOD_UART_TO_MEM;
		for (k = 0; k < MEM_BYTES; k = k + 1) begin
            //send_byte(memory[k], rxd_uart_to_mem);
            rxd_uart_to_mem = 1'b0;
            #BIT_PERIOD_UART_TO_MEM;
            //rxd_uart_to_mem = 1'b0; //send second start bit because of weird uart
            //#BIT_PERIOD_UART_TO_MEM;
            //because of the blocking assignments in the uart mem module that have been changed to non-blocking assignments, 9 bytes are sent every time (two stop bits are sent)
            for (i = 0; i < 8; i = i + 1) begin
                rxd_uart_to_mem = memory[k][i];
                dummy_signal_debug = ~dummy_signal_debug;
                #BIT_PERIOD_UART_TO_MEM;
            end
            rxd_uart_to_mem = 1'b1;
            #BIT_PERIOD_UART_TO_MEM;
            #(5*BIT_PERIOD_UART_TO_MEM); //wait between the bytes to avoid conflicts with the tx part
        end
		*/

		//#BIT_PERIOD_UART_TO_MEM;
		ctrl_bytes[0] = 8'h41;
		ctrl_bytes[1] = 8'h60; //write to sram1
		ctrl_bytes[2] = 8'h80;
		//outer loop: for every word that is written to mem
		for (word_idx = 0; word_idx < MEM_BYTES; word_idx = word_idx + 4) begin
			//ctrl_bytes[2] = ctrl_bytes[2] + word_idx;
			word = {memory[word_idx+3], memory[word_idx+2], memory[word_idx+1], memory[word_idx]};
			flat_ctrl_bytes = {ctrl_bytes[2] + word_idx, ctrl_bytes[1], ctrl_bytes[0]};
			uart_to_mem_send_word(flat_ctrl_bytes, word);
			 
			/*
			//for each word send three control bytes first (41, 60, addr)
			for (ctrl_byte_idx = 0; ctrl_byte_idx < 3; ctrl_byte_idx = ctrl_byte_idx + 1) begin
				send_byte = ctrl_bytes[ctrl_byte_idx];
				if (ctrl_byte_idx == 2) begin
					send_byte = ctrl_bytes[ctrl_byte_idx] + word_idx;
				end

				//send start bit
				rxd_uart_to_mem = 1'b0;
				#BIT_PERIOD_UART_TO_MEM;
				//send ctrl bits
				for (bit_idx = 0; bit_idx < 8; bit_idx = bit_idx + 1) begin
					rxd_uart_to_mem = send_byte[bit_idx];
					//dummy_signal_debug = ~dummy_signal_debug;
					#BIT_PERIOD_UART_TO_MEM;
				end
				//send stop bit
				rxd_uart_to_mem = 1'b1;
				#BIT_PERIOD_UART_TO_MEM;
				#(5*BIT_PERIOD_UART_TO_MEM); //wait between the bytes to avoid conflicts with the tx part
			end

			for (data_byte_idx = 0; data_byte_idx < 4; data_byte_idx = data_byte_idx + 1) begin
				send_byte = memory[data_byte_idx + word_idx]; //send the instructions for the core

				//send start bit
				rxd_uart_to_mem = 1'b0;
				#BIT_PERIOD_UART_TO_MEM;
				//send data bits
				for (bit_idx = 0; bit_idx < 8; bit_idx = bit_idx + 1) begin
					rxd_uart_to_mem = send_byte[bit_idx];
					#BIT_PERIOD_UART_TO_MEM;
				end
				//send stop bit
				rxd_uart_to_mem = 1'b1;
				#BIT_PERIOD_UART_TO_MEM;
				#(5*BIT_PERIOD_UART_TO_MEM); //wait between the bytes to avoid conflicts with the tx part
			end
			//#(5*BIT_PERIOD_UART_TO_MEM); //wait between the bytes to avoid conflicts with the tx part
			
		end
		*/

		RSTB <= 1'b0;
		#2000;
		RSTB <= 1'b1;	    	// Release resetB

		//#BIT_PERIOD_UART_TO_MEM;
		ctrl_bytes[0] = 8'h41;
		ctrl_bytes[1] = 8'h64; //write to sram2 
		ctrl_bytes[2] = 8'h80;
		//outer loop: for every word that is written to mem
		for (word_idx = 0; word_idx < MAX_BITBYTES; word_idx = word_idx + 4) begin
			//ctrl_bytes[2] = ctrl_bytes[2] + word_idx;
			//uart_to_mem_send_word(ctrl_bytes[0], ctrl_bytes[1], ctrl_bytes[2], bitstream[word_idx]);
			/*
			//for each word send three control bytes first (41, 60, addr)
			for (ctrl_byte_idx = 0; ctrl_byte_idx < 3; ctrl_byte_idx = ctrl_byte_idx + 1) begin
				send_byte = ctrl_bytes[ctrl_byte_idx];
				if (ctrl_byte_idx == 2) begin
					send_byte = ctrl_bytes[ctrl_byte_idx] + word_idx;
				end

				//send start bit
				rxd_uart_to_mem = 1'b0;
				#BIT_PERIOD_UART_TO_MEM;
				//send ctrl bits
				for (bit_idx = 0; bit_idx < 8; bit_idx = bit_idx + 1) begin
					rxd_uart_to_mem = send_byte[bit_idx];
					//dummy_signal_debug = ~dummy_signal_debug;
					#BIT_PERIOD_UART_TO_MEM;
				end
				//send stop bit
				rxd_uart_to_mem = 1'b1;
				#BIT_PERIOD_UART_TO_MEM;
				#(5*BIT_PERIOD_UART_TO_MEM); //wait between the bytes to avoid conflicts with the tx part
			end

			for (data_byte_idx = 0; data_byte_idx < 4; data_byte_idx = data_byte_idx + 1) begin
				send_byte = bitstream[data_byte_idx + word_idx]; //send the instructions for the core

				//send start bit
				rxd_uart_to_mem = 1'b0;
				#BIT_PERIOD_UART_TO_MEM;
				//send data bits
				for (bit_idx = 0; bit_idx < 8; bit_idx = bit_idx + 1) begin
					rxd_uart_to_mem = send_byte[bit_idx];
					#BIT_PERIOD_UART_TO_MEM;
				end
				//send stop bit
				rxd_uart_to_mem = 1'b1;
				#BIT_PERIOD_UART_TO_MEM;
			end
			#(5*BIT_PERIOD_UART_TO_MEM); //wait between the bytes to avoid conflicts with the tx part
			*/
		end


		// Repeat cycles of 1000 clock edges as needed to complete testbench
                repeat (100) begin
			repeat (1000) @(posedge clock);
                        $display("+1000 cycles");
		end
		$display("%c[1;31m",27);
		`ifdef GL
			$display ("Monitor: Timeout, Test Mega-Project WB Port (GL) Failed");
		`else
			$display ("Monitor: Timeout, Test Mega-Project WB Port (RTL) Failed");
		`endif
		$display("%c[0m",27);
		$finish;
	end

	//pass 3 ctrl bytes and current word to be sent
	//not using output rx but global variable rxd_uart_to_mem to continuously assign value
	task uart_to_mem_send_word(input [23:0] ctrl, input [31:0] word);
		integer ctrl_byte_idx, bit_idx, data_byte_idx;
		//reg [7:0] send_byte;
		//reg [7:0] ctrl [2:0]; 
		//ctrl[0] = ctrl0;
		//ctrl[1] = ctrl1;
		//ctrl[2] = ctrl2;
		//for each word send three control bytes first (41, 60, addr)
		for (ctrl_byte_idx = 0; ctrl_byte_idx < 3; ctrl_byte_idx = ctrl_byte_idx + 1) begin
			//send_byte = ctrl[ctrl_byte_idx];
			/*if (ctrl_byte_idx == 2) begin
				send_byte = ctrl[ctrl_byte_idx] + word_idx;
			end*/

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
			#(5*BIT_PERIOD_UART_TO_MEM); //wait between the bytes to avoid conflicts with the tx part
		end

		for (data_byte_idx = 0; data_byte_idx < 4; data_byte_idx = data_byte_idx + 1) begin
			//send_byte = word[data_byte_idx]; //send the data

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
			#(5*BIT_PERIOD_UART_TO_MEM); //wait between the bytes to avoid conflicts with the tx part
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
	end

        initial begin
           wait(checkbits == 16'h0004);
           $display ("Monitor: ibex Passed");
           #7000;
           $finish;
        end


        initial begin
           wait(checkbits == 16'h0005);
           $display ("Monitor: ibex Failed");
           #7000;
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
