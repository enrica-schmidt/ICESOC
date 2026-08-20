# SRAM paging simulation
Study project by Enrica Schmidt, finished 17/08/2026

## Motivation
The ICESOC has two 1KB SRAMs on chip, which can therefore store 1KB/4=256 words each.
The Ibex cores assume the SRAM to be byte-addressable with one signal, but it actually is word-addressed by that signal and has a separate byte-enable signal to select the bytes within a word. 
Because of this mismatch, only every fourth word is addressable by the cores. 
So the SRAM effectively shrinks to 256/4=64 words per SRAM. This is much too small to hold a sensible program, let alone the entire bitstream. 
Because of this, a mechanism is implemented here, which loads the bitstream and the instructions piece by piece into the SRAM and processes them accordingly.
The SRAM is split into physical pages. 

The size of the pages is controlled by the parameters BITSTR_WORDS_PER_PAGE, and INSTRS_WORDS_PER_PAGE in instr_bitstr_sizes.h. 
The total number of words in the bitstream and instructions are given by BITSTREAM_WORDS, and INSTRUCTION_WORDS. 
A full bitstream has 4506 words.

When modifying the bitstream or program files, it needs to be made sure that the parameters in instr_bitstr_sizes.h are adapted accordingly to match the total nr of instructions and bitstream words in both files. When changing the program, the first three pages A, B, and C which are marked as such with comments should not be modified. After page C, pages 1, 2 etc. can be filled however with a few things to keep in mind. Firstly, each page needs to start with the instruction "jalr ra, s5, 0x0", which calls a function, which is permanently located in SRAM1, to increment the page request counter and therefore request the next page to be loaded into SRAM. Every page needs to end with the instruction "jalr zero, s5, 32", which calls a paging function which checks if the next page is available already and if so, jumps to the next page. Every label used should be unique. For now, every label has the index of its page appended to it. As long as labels don't repeat, this can theoretically be handled otherwise. The code in program.s needs to be split into pages. The pages have no knowledge of each other, so they can always just call the next one but never go back or dynamically call anything. So the code is essentially executed sequentially page by page. Every page needs to be standalone. An exception is page C, which is permanently kept in SRAM1. This page contains the requesting and paging functions needed in every other page. 
Every page except for the first three pages A, B, and C, have to have exactly the number of instructions specified in INSTRS_WORDS_PER_PAGE, since the instructions are counted and loaded into SRAM page-wise this way. So if less instructions are needed than that page size, the page needs to be padded with nops.

## Ibex program
In the folder verilog/dv/paging/gen_header/program, there is the file program.s, which contains the RISC-V assembly program for the ibex core on the ICESOC. The program is split into pages, which are separated by comments. It is important that every page has exactly INSTRS_WORDS_PER_PAGE instructons, which is specified in instr_bitstr_sizes.h. Currently the page size for the instructions is set to 32. When compiling program.s, the instructions are simply counted and every 32 instructions a new page starts, which will be loaded into memory one after another. This means, when writing the program.s, the programmer needs to make sure that every block of INSTRS_WORDS_PER_PAGE instructions is independent of the others and a closed unit. If less than INSTRS_WORDS_PER_PAGE instructions have been used, the page manually needs to be padded with nops. The pages are independent of each other and have no knowledge of each other. The paging mechanism works, because the variables needed are stored in registers s0-s5, which keep their value between the pages. This means that these six registers can never be used for anything except the paging mechanism when modifying program.s.
In the firmware for the Caravel mgmt core, wb_test_icesoc.c, the file instr_bitstr_sizes.h is included, which contains the parameters BITSTREAM_WORDS, INSTRUCTION_WORDS, BITSTR_WORDS_PER_PAGE, and INSTRS_WORDS_PER_PAGE. They need to be kept consistent with the contents of program.s. 

## Bitstream
The bitstream is stored in verilog/dv/paging/bitstreams/bitstream.h as a volatile static const uint32_t array. It is included in the Caravel firmware (through the instr_bitstr_sizes.h).

## How to use
- create a file environment_vars.txt inside verilog/dv/paging, specifying the following paths: <br />
GCC_PATH= <br />
GCC_PREFIX= <br />
PDK_ROOT= <br />

- make sure the oss-cad-suite/environment is sourced (or the tools installed locally and added to the path)

bitstream:
- modify user_design/top.v in ICESOC_FABulous_user_project as desired
- regenerate bitstream from Test folder with make build_test_design
- copy user_design/top.v, Test/build/top.hex, and Test/build/top.vh into gen_header/bitstream and rename top to a more descriptive name (same for all three files so it is clear that they belong to the same design)
- use "python generate_header.py input_name.hex output_name.h" to generate a header file from the hex file
- copy the .h and .vh files into verilog/dv/paging/bitstreams

ibex program:
- in verilog/dv/paging/gen_header/program, copy program.s and think of a more descriptive name for the file
- modify the numeric pages 1, and 2 as desired. add pages if needed
- make sure the number of instructions per page match the parameter INSTRS_WORDS_PER_PAGE in instr_bitstr_sizes.h (each page is separated with comments from the others for readability)
- make sure the number of numeric pages * INSTRS_WORDS_PER_PAGE match INSTRUCTION_WORDS
- make sure each page starts with "jalr ra, s5, 0x0", and ends with "jalr zero, s5, 32"
- don't use pseudoinstructions that would expand to multiple instructions when compiled, since that would mess up the instruction count
- if a custom instruction should be used, write it as a nop instead for now (or modify GCC to compile custom instructions automatically)
- use verilog/dv/paging/gen_header/program make program_name.h to generate the header file from the .s file
- in the header file, replace the nop (0x00000013) with the hex value of the custom instruction that should be used instead (make sure to replace the correct nop by counting the instructions)
- copy the header file to verilog/dv/paging/programs <br />
<br />
<br />

Then modify instr_bitstr_sizes.h to match the number of instructions per page and the number of total instructions (for the bitstream, the words per page could be modified but this is not necessary).
Include the .h file of the desired program from the programs folder and the .h file of the desired bitstream from the bitstreams folder.

if the bitstream paging should be simulated:
- set BITSTREAM_WORDS 4506 in instr_bitstr_sizes.h
- in verilog/dv/paging/Makefile, remove -DEMULATION from SIM_DEFINES
- remove the line "${BITSTR\_DIR}/${DESIGN}.vh \" from the iverilog command
- start the simulation from the paging folder with "make RUN_DIR=name_of_simulation_run"

if the bitstream paging should not be simulated (faster): 
- set BITSTREAM_WORDS 0 in instr_bitstr_sizes.h
- in verilog/dv/paging/Makefile, add -DEMULATION to SIM_DEFINES
- add the line "${BITSTR\_DIR}/${DESIGN}.vh \" to the iverilog command
- start the simulation from the paging folder with "make RUN_DIR=name_of_simulation_run"

## Glossary
Caravel management (mgmt) core firmware: "paging/wb_test_icesoc.c"
Program for the ibex core (core 1) in the ICESOC : "paging/gen_header/program/program.s"
Bitstream : "paging/gen_header/bitstream/bitstream.hex" To configure the eFPGA. Is loaded into SRAM by the Caravel management core and sent to the Config part of the eFPGA by the ibex core using the custom instruction 000ff00b = "eFPGA0d0 zero, t6, zero". This sets the delay as 0, source register 1 as t6, source register 2 and the destination register as zero, and the slot to 11, which means that the eFPGA will be configured with this instruction. The value in t6 will be written to the eFPGA config interface. SelfWriteStrobe and SelfWriteData are set accordingly by the hardware. The bitstream is loaded into reg t6 word by word by the ibex core and sent to the eFPGA with the custom instruction.