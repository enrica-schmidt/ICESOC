# SRAM paging simulation
## Ibex program
In the subfolder program_and_bitstream/ibex_program, there is the file program.s, which contains the assembly program for the ibex core on the ICESOC. The program is split into pages, which are separated by comments. It is important that every page has exactly as many instructions, as PAGE_SIZE_INSTRS/4 in wb_test_icesoc.c. Currently the page size for the instructions is set to 256 there. This means, the page spans 256 addresses in SRAM. Since only every fourth address is reachable by the core, this means every page contains 256/4 = 64 words. When compiling the program.s, the instructions are simply counted and every 64 instructions a new page starts, which will be loaded into memory one after another. This means, when writing the program.s, the programmer needs to make sure that every block of page_size instructions is independent of the others and a closed unit. If less than page_size instructions have been used, the page manually needs to be padded with nops. The pages are independent of each other and have no knowledge of each other. The paging mechanism works, because the four variables needed are stored in registers s0-s3, which keep their value between the pages. This means that these four registers can never be used for anything except the paging mechanism when modifying program.s.
In the firmware for the Caravel mgmt core, wb_test_icesoc.c, the parameters NUM_INSTR, PAGE_SIZE_INSTRS, and NUM_PAGES_INSTRS need to be kept consistent with the contents of program.s. 
NUM_INSTR are the number of instructions in program.s. This should be a multiple of PAGE_SIZE_INSTRS/4, depending on how many pages the program contains. NUM_PAGES_INSTRS is the number of physical pages SRAM 1 is split into, and PAGE_SIZE_INSTRS is the size of each of these pages. 
Since SRAM



#define MAX_BITBYTES 20 //change this back to 20000
#define NUM_INSTR 192 //nr of instructions to be written to sram (PAGE_SIZE_INSTRS/4 * nr of virtual pages)
#define MEM_BYTES (NUM_INSTR * 4) //4 bytes written per instruction
#define PAGE_SIZE_BITSTR 256 //nr words per page, only 1/4th is addressable
#define NUM_PAGES_BITSTR 2 //nr of physical pages
#define PAGE_SIZE_INSTRS 256 //nr words per page, only 1/4th is addressable
#define NUM_PAGES_INSTRS 2 //nr of physical pages