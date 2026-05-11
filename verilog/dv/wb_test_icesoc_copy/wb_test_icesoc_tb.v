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
	integer address, iteration;

	wire gpio;
	wire [37:0] mprj_io;
	wire [15:0] checkbits;
	wire [31:0]sram_address;

	logic rxd_uart_to_mem; //, txd_uart_from_mem;
	integer word_idx, fd;
	logic dummy_signal_debug;

	assign checkbits = mprj_io[31:16];
	assign sram_address = mprj_io[31:0];

	assign mprj_io[9] = rxd_uart_to_mem; //send data from testbench to icesoc (write to sram)

	//assign mprj_io[3] = (CSB == 1'b1) ? 1'b1 : 1'bz;

	// External clock is used by default.  Make this artificially fast for the
	// simulation.  Normally this would be a slow clock and the digital PLL
	// would be the fast clock.

	always #(CLK_PER/2) clock <= (clock === 1'b0);

	initial begin
		clock = 0;
	end

	localparam CLK_PER = 2 * 12.5;

	initial begin
		$dumpfile("wb_test_icesoc.vcd");
		$dumpvars(0, wb_test_icesoc_tb);
		for (address = 0; address < 256; address = address + 4) begin
			$dumpvars(0, wb_test_icesoc_tb.uut.chip_core.mprj.inst_eFPGA_CPU_top.icesoc_top_i.sram_1_i.mem[address]);
			$dumpvars(0, wb_test_icesoc_tb.uut.chip_core.mprj.inst_eFPGA_CPU_top.icesoc_top_i.sram_2_i.mem[address]);
		end

		RSTB <= 1'b0;
		#2000;             //hold reset for 2000ns
		RSTB <= 1'b1;        // Release resetB

		iteration = 0;
		repeat (65) begin
			repeat (10000) @(posedge clock);
            $display("+1000 cycles %0d", iteration);
			iteration = iteration + 1;
		end
		$finish;
	end

	reg [31:0] checkpoint;
	reg [ 7:0] ibex_ctrl;
	initial begin
		ibex_ctrl = 8'b0000_0110;
	   	wait(checkbits == 16'h0001);
	   	$display("Monitor: MPRJ-Logic WB Started [T=%0t]", $realtime);
	   	wait(checkbits == 16'h0002);
	   	$display("Monitor: Program ibex [T=%0t]", $realtime);
		wait(checkbits == 16'h0007); //after the first two instruction pages are written
	   	$display("Monitor: Start ibex (instruction pages A and B are ready) [T=%0t]", $realtime);
		ibex_ctrl = 8'b0010_0110; //set mprj_io[5]=fetch_enable_1=1 to start ibex core
		//start and finish bitstream upload
	end

	initial begin
		wait(checkbits == 16'h0004);
		$display ("Monitor: ibex Passed [T=%0t]", $realtime);
		//#7000;
		//$finish;
	end


	initial begin
		wait(checkbits == 16'h0005);
		$display ("Monitor: ibex Failed [T=%0t]", $realtime);
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
