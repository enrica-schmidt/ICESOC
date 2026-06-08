#ifndef INSTR_BITSTR_SIZES_H
#define INSTR_BITSTR_SIZES_H

#include "memory.h"
#include "bitstream.h"

#define BITSTREAM_WORDS 32//4506 //full bitstream 4506 words
#define INSTRUCTION_WORDS 80 //nr of instructions to be written to sram (not including page A-C) (PAGE_SIZE_INSTRS/4 * nr of virtual pages)

#define BITSTR_WORDS_PER_PAGE 16 //nr words per page, only 1/4th is addressable
#define INSTRS_WORDS_PER_PAGE 16 //nr words per page, only 1/4th is addressable

#endif /* INSTR_BITSTR_SIZES_H */