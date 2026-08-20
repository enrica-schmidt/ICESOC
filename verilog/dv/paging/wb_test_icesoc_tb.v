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
//`include "bitstreams/top_f.vh"

module wb_test_icesoc_tb;
	reg clock;
	reg RSTB;
	reg power1, power2;
	reg power3, power4;
	integer address, iteration, i;

	wire gpio;
	wire [37:0] mprj_io;
	wire [3:0] checkbits;

	assign checkbits = mprj_io[31:28];

	// External clock is used by default.  Make this artificially fast for the
	// simulation.  Normally this would be a slow clock and the digital PLL
	// would be the fast clock.

	localparam CLK_PER = 2 * 25;
	always #(CLK_PER/2) clock <= (clock === 1'b0);

	initial begin
		clock = 0;
	end

	initial begin
		//unit: -6: microseconds us, 3: digits after decimal point, " us": microseconds string, 13: min field width (to how many places the number will be padded with spaces for lining up)
		$timeformat(-6, 3, " us", 13); 
	end

	initial begin
		/*
		$dumpfile("wb_test_icesoc.fst");
		$dumpvars(1, wb_test_icesoc_tb);
		//$dumpvars(0, wb_test_icesoc_tb.mprj_io);
		$dumpvars(0, wb_test_icesoc_tb.uut.chip_core.mprj.inst_eFPGA_CPU_top.CLK);
		$dumpvars(0, wb_test_icesoc_tb.uut.chip_core.mprj.inst_eFPGA_CPU_top.SelfWriteData);
		$dumpvars(0, wb_test_icesoc_tb.uut.chip_core.mprj.inst_eFPGA_CPU_top.SelfWriteStrobe);
		$dumpvars(0, wb_test_icesoc_tb.uut.chip_core.mprj.inst_eFPGA_CPU_top.fetch_enable_1);
		$dumpvars(0, wb_test_icesoc_tb.uut.chip_core.mprj.inst_eFPGA_CPU_top.io_in);
		$dumpvars(0, wb_test_icesoc_tb.uut.chip_core.mprj.inst_eFPGA_CPU_top.io_out);
		$dumpvars(0, wb_test_icesoc_tb.uut.chip_core.mprj.inst_eFPGA_CPU_top.io_oeb);
		$dumpvars(0, wb_test_icesoc_tb.uut.chip_core.mprj.inst_eFPGA_CPU_top.W_OPA);
		$dumpvars(0, wb_test_icesoc_tb.uut.chip_core.mprj.inst_eFPGA_CPU_top.W_OPB);
		$dumpvars(0, wb_test_icesoc_tb.uut.chip_core.mprj.inst_eFPGA_CPU_top.W_RES0);
		$dumpvars(0, wb_test_icesoc_tb.uut.chip_core.mprj.inst_eFPGA_CPU_top.W_RES1);
		$dumpvars(0, wb_test_icesoc_tb.uut.chip_core.mprj.inst_eFPGA_CPU_top.W_RES2);
		$dumpvars(0, wb_test_icesoc_tb.uut.chip_core.mprj.inst_eFPGA_CPU_top.eFPGA_operand_a_1_o);
		$dumpvars(0, wb_test_icesoc_tb.uut.chip_core.mprj.inst_eFPGA_CPU_top.gen_eFPGA.Inst_eFPGA);
		$dumpvars(0, wb_test_icesoc_tb.uut.chip_core.mprj.inst_eFPGA_CPU_top.icesoc_top_i.ibex_core_1.u_ibex_core.instr_rdata_i);
		
		for (address = 0; address < 256; address = address + 4) begin
			$dumpvars(0, wb_test_icesoc_tb.uut.chip_core.mprj.inst_eFPGA_CPU_top.icesoc_top_i.sram_1_i.mem[address]);
			$dumpvars(0, wb_test_icesoc_tb.uut.chip_core.mprj.inst_eFPGA_CPU_top.icesoc_top_i.sram_2_i.mem[address]);
		end
		*/

		RSTB <= 1'b0;
		#2000;             //hold reset for 2000ns
		RSTB <= 1'b1;        // Release resetB

		
		/*
		i = 0;
		repeat (2000) begin
			repeat (10000) @(posedge clock);
            $display("+10 000 cycles %0d", i);
			$display("bitstream page ready: 0x%0h", wb_test_icesoc_tb.uut.chip_core.mprj.inst_eFPGA_CPU_top.icesoc_top_i.sram_1_i.mem[24]);
			i = i + 1;
		end
		$finish;
		*/
		
	end

	//reg [31:0] checkpoint;
	reg [ 7:0] ibex_ctrl;
	initial begin
		ibex_ctrl = 8'b0000_0110;
	   	wait(checkbits == 4'h1);
	   	$display("Monitor: MPRJ-Logic WB Started [T=%t]", $realtime);
	   	wait(checkbits == 4'h2);
	   	$display("Monitor: Program ibex [T=%t]", $realtime);
		wait(checkbits == 4'h3); //after the first two instruction pages are written
	   	$display("Monitor: Start ibex (instruction pages A and B are ready) [T=%t]", $realtime);
		ibex_ctrl = 8'b0010_0110; //set mprj_io[5]=fetch_enable_1=1 to start ibex core
		//start and finish bitstream upload
	end

	initial begin
		iteration = 0;
		forever begin
			repeat (100000) @(posedge clock);
            $display("+100 000 cycles %0d [T=%t]", iteration, $realtime);
			$display("bitstream page ready: 0x%0h", wb_test_icesoc_tb.uut.chip_core.mprj.inst_eFPGA_CPU_top.icesoc_top_i.sram_1_i.mem[24]);
			$fflush();
			iteration = iteration + 1;
			if (iteration >= 200) begin
				$display("reached 200 iterations. finish now.");
				$fflush();
				$finish;
			end
		end
	end

	reg [1:0] fabric_ctrl;
	assign mprj_io[18:17] = fabric_ctrl;
	initial begin
		fabric_ctrl = 2'b00;
		wait(checkbits == 4'h4);
		$display ("Monitor: ibex Passed [T=%t]", $realtime);
		$display("-------------------------------------------------");
		$display("CRC result unaccelerated (only on ibex core): 0x%h", wb_test_icesoc_tb.uut.chip_core.mprj.inst_eFPGA_CPU_top.icesoc_top_i.sram_1_i.mem[16]);
		$display("CRC result accelerated (using CI on fabric):  0x%h", wb_test_icesoc_tb.uut.chip_core.mprj.inst_eFPGA_CPU_top.icesoc_top_i.sram_1_i.mem[24]);
		$display("# clk cycles unaccelerated: 0x%h", wb_test_icesoc_tb.uut.chip_core.mprj.inst_eFPGA_CPU_top.icesoc_top_i.sram_1_i.mem[20]);
		$display("# clk cycles accelerated:   0x%h", wb_test_icesoc_tb.uut.chip_core.mprj.inst_eFPGA_CPU_top.icesoc_top_i.sram_1_i.mem[28]);
		$display("-------------------------------------------------");
		$display ("Monitor: Setting rst and en for fabric [T=%t]", $realtime);
		fabric_ctrl[0] = 1'b1; //set input io_in[17] of user project to 1 (rst=1 to fabric)
		fabric_ctrl[1] = 1'b1; //set input io_in[18] of user project to 1 (en=1 to fabric)
		#(CLK_PER * 5);
		fabric_ctrl[0] = 1'b0; //deassert reset so counter on fabric starts counting
		$display ("Monitor: Counter rst deasserted [T=%t]", $realtime);
		#(CLK_PER * 10000); // let the counter count
		#7000;
		$display ("Monitor: Counter at %0d [T=%t]", mprj_io[26:19], $realtime);
		$finish;
	end

	/*
	initial begin
		// This checks if the flag was set during compilation
		`ifdef EMULATION
			$display("[INIT] EMULATION flag is DEFINED.");
		`else
			$display("[INIT] EMULATION flag is NOT DEFINED. (Warning: Bitstream might not load!)");
		`endif
	end

	initial begin
		// Print in Hexadecimal (shorter, easier to spot-check)
		$display("X4Y1: %b", `Tile_X4Y1_Emulate_Bitstream);
		$display("X5Y1: %b", `Tile_X5Y1_Emulate_Bitstream);
	end
	*/

	initial begin
		wait(checkbits == 4'h5);
		$display ("Monitor: ibex Failed [T=%t]", $realtime);
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
