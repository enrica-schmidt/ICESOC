#written by Enrica for SRAM paging
main:           jal ra, deadbeef        #call function deadbeef that writes deadbeef to addr 0x004
                addi a0, x0, 64         #a0=page_size
                addi a1, x0, 2          #a1=page_nr (how many pages)
                lui a2, 5
                addi a2, a2, -480       #a2=bitstream_words (nr words in bitstream (20000))
                jal ra, load_bitstream #call function load_bitstream
                jal ra, instr_paging

#write deadbeef to address 0x004 to pass test
deadbeef:       lui t0, 0xdeadc
                addi t0, t0, -273       #t0=deadbeef
                sw t0, 0x004(zero)      #mem[0x004]=deadbeef
                jalr zero, 0(ra)

#load the bitstream from SRAM into the eFPGA
load_bitstream: addi t0, zero, 0x0
                addi t1, zero, 0x480
                addi t2, zero, 0x0
                addi t3, t1, 0x0
first_page:     lw t6, 0x400(zero)
                bne t6, t2, first_page
read_page:      add t4, t3, a0
                addi t5, t3, 0x0
config:         lw t6, 0(t5)
                nop
                addi t0, t0, 0x1
                beq t0, a2, done_bitstr
                addi t5, t5, 0x4
                blt t5, t4, config
poll_bitstr:    lw t6, 0x400(zero)
                bne t6, t2, poll_bitstr
                addi t2, t2, 0x1
                add t3, t3, a0
                bne t2, a1, read_page
                addi t2, zero, 0x0
                addi t3, t1, 0x0
                j read_page
done_bitstr:    jalr zero, 0(ra)

#check if the new page with instructions is ready
instr_paging:   addi s0, zero, 128      #s0: start address of current page
                addi s1, zero, 1        #s1: expected "counter" value if next page is loaded, (toggles 0/1)
poll_ctr:       lw t0, 0(zero)
                bne t0, s1, poll_ctr
                xori s1, s1, 1
                bne s1, zero, page2_mem
                addi s0, s0, 256
                j next_mem
page2_mem:      addi s0, s0, -256
next_mem:       jalr zero, s0, 0




    
