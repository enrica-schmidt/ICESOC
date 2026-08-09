#SRAM paging
#### page A ###########################################################@0x80
initA:          addi sp, zero, 0xac         #stack pointer=middle of sram1(before boot addr)
                #because sp is decremented before writing, the first word on the stack is written to addr 0x7c
                lw s0, 0x0(zero)            #s0: instr_page_size (mem[0x0])
                lw s1, 0x4(zero)            #s1: instr_nr_pages (mem[0x4])
                lw a0, 0x10(zero)           #a0: bitstr_page_size
                lw a1, 0x14(zero)           #a1: bitstr_nr_pages
                lw a2, 0x20(zero)           #a2: bitstream_words
                addi s5, zero, 0xac         #s5: addr where req_next is
pagingA:        addi s2, zero, 0x400        #s2: start address of next page, beginning of sram2
next_pageA:     jalr zero, s2, 0            #move PC to start address of next page

#### page B ###########################################################@0x400
req_all_bitB:   beq a2, zero, pagingB       #if bitstream length==0, skip bitstream paging
                addi t5, a1, -1             #request all pages (up to bitstr_nr_pages-1)
                sw t5, 0x1c(zero)           #mem[0x1c]=bitstr_page_request
load_bitstreamB:addi t0, zero, 0x0          #t0: word_ctr = 0
                addi t1, zero, 0x80         #t1: start_first_page = 0x80
                addi t2, zero, 0x0          #t2: page_ctr_modulo = 0
                addi t3, t1, 0x0            #t3: start_page = start_first_page
                addi t4, zero, 0x0          #t4: page_ctr
first_pageB:    lw t6, 0x18(zero)           #bitstr_page_ready=mem(0x18 = sram1[24])
                bgeu t6, t5, first_pageB    #init value is 0xffffffff, so the page is ready when the counter has a value between 0 and bitstr_nr_pages-1, which is still in reg t5
read_pageB:     addi t5, t3, 0x0            #t5: read_addr = start_page
configB:        lw t6, 0(t5)
                nop #0x000ff00b -> eFPGA3d0 zero, t6, zero (configure with contents of t6)
                addi t0, t0, 0x1
                beq t0, a2, pagingB         #the entire bitstream was read, next request new instr pages
                addi t5, t5, 0x4            #increment read_addr
                add t6, t3, a0              #end_page = start_page + page_size
                blt t5, t6, configB
req_nextB:      lw t6, 0x1c(zero)           #read page request counter
                addi t6, t6, 1              #increment page request counter 
                sw t6, 0x1c(zero)           #store new page request counter
                addi t2, t2, 0x1            #page_ctr_modulo++
                addi t4, t4, 0x1            #page_ctr++
                add t3, t3, a0              #start_page += page_size
                bne t2, a1, poll_bitstrB    #check if modulo counter has reached last page, if so reset it
                addi t2, zero, 0x0
                addi t3, t1, 0x0            #start at first physical page again 
poll_bitstrB:   lw t6, 0x18(zero)           #bitstr_page_ready=mem(0x18 = sram2[0])
                blt t6, t4, poll_bitstrB    #use ctr, not modulo ctr for hard check
                j read_pageB
pagingB:        addi s2, zero, 0x400        #s2: start address of next page; start_page += page_size
                addi s3, zero, 1            #s3: page counter
                addi s4, zero, 0            #s4: page counter modulo++
                j req_pagesB
                nop
                nop
                nop
                nop
                nop
                nop
                nop
                nop
                nop
                nop
                nop
                nop
                nop
                nop
                nop
                nop
                nop
                nop
                nop
                nop
                nop
                nop
                nop
                nop
                nop
req_pagesB:     addi t1, s1, -1              #request instr_nr_pages-1 pages
                sw t1, 0xc(zero)             #store new page request counter
                #poll page ready counter (should be 2), to check if new page is already there (permanent page with paging function)
#setup the paging variables and goto 0x400 (first real page)
poll_instrB:    lw t0, 0x8(zero)            #instr_page_ready=mem[0x8]
                blt t0, s3, poll_instrB
next_pageB:     jalr zero, s2, 0            #move PC to start address of next page

#### page C ###########################################################@0x80
#this page is written to mem[0x80]=sram1[0x80] and is kept there permanently because every page needs to call these functions
#the values of s0, s1, s2, s3, s4, s5 are preserved between pages (dont use them except for the paging)
req_next:       addi sp, sp, -4
                sw t0, 0(sp)                #store t0 on the stack
                lw t0, 0xc(zero)            #read page request counter
                addi t0, t0, 1              #increment page request counter 
                sw t0, 0xc(zero)            #store new page request counter
                lw t0, 0(sp)                #restore t0 from the stack  
                addi sp, sp, 4
                jalr zero, 0(ra)
paging:         addi sp, sp, -4
                sw t0, 0(sp)
                addi s4, s4, 1              #s4: page counter modulo++
                addi s3, s3, 1              #s3: page counter++ 
                add s2, s2, s0              #s2: start address of next page; start_page += page_size
                bne s4, s1, poll_instr      #if modulo counter has reached last page, start at first page addr again and reset modulo counter
                addi s4, zero, 0
                addi s2, zero, 0x400
poll_instr:     lw t0, 0x8(zero)            #instr_page_ready=mem[0x8]
                blt t0, s3, poll_instr
next_page:      lw t0, 0(sp)
                addi sp, sp, 4
                jalr zero, s2, 0            #move PC to start address of next page

#### page 1 ###########################################################@0x400
#have to pad pages with nops to have a length of exactly page_size
main1:          jalr ra, s5, 0x0            #function call of req_next at addr s5
                lw a0, 0x20(zero)           #load pointer to input data from sram1[0x10]
                lw a1, 0x24(zero)           #load length of input data from sram1[0x14] (in byte)
                csrr t5, mcycle             #Read lower 32 bits into t5 (ignore high bits since the low bits should be enough)
                #sw t5, 0x60(zero)
                jal ra, crc32b_1
                csrr t6, mcycle             #Read lower 32 bits into t0
                sw a0, 0x10(zero)           #write crc result to mem[0x10] (overwrite ptr to input data)
                sub t6, t6, t5              #subtract time at start of crc from time at end
                sw t6, 0x18(zero)
                jalr zero, s5, 32           #function call of paging at addr s5+32 (8 instructions in req_next * 4)
                nop
                nop
                nop
crc32b_1:       addi t0, zero, -1           #t0=0xFFFFFFFF
                lui t4, 0xEDB88             #t4=0xEDB88320 (reflected polynomial)
                addi t4, t4, 800            #t4=0xEDB88320 (reflected polynomial)
byte_loop1:     beq a1,  zero, done1
                lbu  t1, 0(a0)              #load next byte
                xor t0, t0, t1              #fold it into the low byte of crc
                addi t2, zero, 8            #8 bits per byte
bit_loop1:      andi t3, t0, 1              #test LSB (reflected form shifts right)
                srli t0, t0, 1
                beq t3, zero, no_xor1
                xor t0, t0, t4              #if current bit was 1, xor with the polynomial
no_xor1:        addi t2, t2, -1             #decrement bit counter
                bne  t2,  zero, bit_loop1
                addi a0, a0, 1              #increment data pointer by one byte
                addi a1, a1, -1             #decrement data length
                jal zero, byte_loop1
done1:          xori t0, t0, -1             #final XOR with 0xFFFFFFFF (invert all bits)
                add  a0, t0, zero
                jalr zero, ra, 0

#### page 2 ###########################################################@0x480
#have to pad pages with nops to have a length of exactly page_size
main2:          jalr ra, s5, 0x0            #function call of req_next at addr s5
                lw a0, 0x20(zero)           #load pointer to input data from sram1[0x10]
                lw a1, 0x24(zero)           #load length of input data from sram1[0x14] (in byte)
                csrr t5, mcycle             #Read lower 32 bits into t5 (ignore high bits since the low bits should be enough)
                #jal ra, crc32b_2
                csrr t6, mcycle             #Read lower 32 bits into t0
                #sw a0, 0x14(zero)           #write crc result to mem[0x10] (overwrite ptr to input data)
                sub t6, t6, t5              #subtract time at start of crc from time at end
                sw t6, 0x20(zero)
                csrr t5, mcycle             #start 
                nop
                nop
                nop
                nop
                nop
                nop
                nop
                nop
                nop
                nop
                csrr t6, mcycle             #stop
                sub t6, t6, t5              #subtract time at start of crc from time at end
                sw t6, 0x24(zero)
                jalr zero, s5, 32           #function call of paging at addr s5+32 (8 instructions in req_next * 4)
                nop
                nop
                nop
                nop
                nop
                nop
                nop
                nop
crc32b_2:       nop
                jalr zero, ra, 0
