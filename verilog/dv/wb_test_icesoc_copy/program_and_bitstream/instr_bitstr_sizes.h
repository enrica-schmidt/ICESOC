#ifndef INSTR_BITSTR_SIZES_H
#define INSTR_BITSTR_SIZES_H

#include "memory.h"
#include "bitstream.h"

#define BITSTREAM_WORDS 72 //full bitstream 5000 words
#define INSTRUCTION_WORDS 80 //nr of instructions to be written to sram (not including page A-C) (PAGE_SIZE_INSTRS/4 * nr of virtual pages)

#define BITSTR_WORDS_PER_PAGE 16 //nr words per page, only 1/4th is addressable
#define BITSTR_NR_PHYS_PAGES 2 //nr of physical pages
#define INSTRS_WORDS_PER_PAGE 16 //nr words per page, only 1/4th is addressable
#define INSTRS_NR_PHYS_PAGES 4 //nr of physical pages

#endif /* INSTR_BITSTR_SIZES_H */