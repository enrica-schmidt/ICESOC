#written by Enrica for SRAM paging
main:           jal ra, deadbeef            #call function deadbeef that writes deadbeef to addr 0x010
                lw a0, 0x404(zero)          #a0=page_size
                lw a1, 0x408(zero)          #a1=nr_pages
                lw a2, 0x40c(zero)          #a2=bitstream_words
                #addi a0, x0, 256           #a0=page_size
                #addi a1, x0, 2             #a1=page_nr (how many pages)
                #lui a2, 5
                #addi a2, a2, -480          #a2=bitstream_words (nr words in bitstream (20000))
                jal ra, load_bitstream      #call function load_bitstream
                lw a0, 0x004(zero)          #a0=page_size
                lw a1, 0x008(zero)          #a1=nr_pages
                jal ra, instr_paging

#write deadbeef to address 0x004 to pass test
deadbeef:       lui t0, 0xdeadc
                addi t0, t0, -273           #t0=deadbeef
                sw t0, 0x010(zero)          #mem[0x010]=deadbeef
                jalr zero, 0(ra)

#load the bitstream from SRAM into the eFPGA
load_bitstream: addi t0, zero, 0x0          #t0: word_ctr = 0
                addi t1, zero, 0x480        #t1: start_first_page = 0x480
                addi t2, zero, 0x0          #t2: page_ctr_modulo = 0
                addi t3, t1, 0x0            #t3: start_page = start_first_page
                addi t4, zero, 0x0          #t4: page_ctr
first_page:     lw t6, 0x400(zero)          #t6 = mem(0x400 = sram2[0])
                bne t6, t4, first_page
read_page:      addi t5, t3, 0x0            #t5: read_addr = start_page
config:         lw t6, 0(t5)
                nop
                addi t0, t0, 0x1
                beq t0, a2, done_bitstr
                addi t5, t5, 0x4
                add t6, t3, a0              #end_page = start_page + page_size
                blt t5, t6, config
                addi t2, t2, 0x1            #page_ctr_modulo++
                addi t4, t4, 0x1            #page_ctr++
                add t3, t3, a0              #start_page += page_size
                bne t2, a1, poll_bitstr
                addi t2, zero, 0x0
                addi t3, t1, 0x0
poll_bitstr:    lw t6, 0x400(zero)
                bne t6, t4, poll_bitstr     #use ctr, not modulo ctr for hard check
                j read_page
done_bitstr:    jalr zero, 0(ra)

#check if the new page with instructions is ready
#call with a0=page_size a1=nr_pages
instr_paging:   addi s0, zero, 0x80         #s0: start address of first page
                addi s1, s0, 0              #s1: start address of current page
                addi s2, zero, 1            #s2: page counter
                #addi s2, s2, 0x1           #page_ctr++
                add s1, s1, a0              #start_page += page_size
                bne s2, a1, poll_ctr
                addi s2, zero, 0x0
                addi s1, s0, 0x0
poll_ctr:       lw t0, 0x0(zero)
                bne t0, s2, poll_ctr
next_page:      jalr zero, s1, 0            #move PC to start address of next page
