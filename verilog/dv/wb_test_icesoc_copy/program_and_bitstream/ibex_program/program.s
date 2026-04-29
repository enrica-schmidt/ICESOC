#SRAM paging
#### page 0 ####################################################################################################
start:          lw t6, 0x00(zero)
                bne t6, zero, start
req_all:        lw a1, 0x8(zero)            #a1=nr_pages  
                addi t0, a1, -1
                sw t0, 0xc(zero)
main:           jal ra, deadbeef            #call function deadbeef that writes deadbeef to addr 0x010
                lw a0, 0x404(zero)          #a0=page_size
                lw a1, 0x408(zero)          #a1=nr_pages
                lw a2, 0x410(zero)          #a2=bitstream_words
                jal ra, load_bitstream      #call function load_bitstream
                lw a0, 0x4(zero)            #a0=page_size
                lw a1, 0x8(zero)            #a1=nr_pages                    
                jal zero, init_paging
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
                addi t5, t5, 0x4            #increment read_addr
                add t6, t3, a0              #end_page = start_page + page_size
                blt t5, t6, config
                addi t2, t2, 0x1            #page_ctr_modulo++
                addi t4, t4, 0x1            #page_ctr++
                add t3, t3, a0              #start_page += page_size
                bne t2, a1, poll_bitstr     #check if modulo counter has reached last page, if so reset it
                addi t2, zero, 0x0
                addi t3, t1, 0x0
poll_bitstr:    lw t6, 0x400(zero)
                bne t6, t4, poll_bitstr     #use ctr, not modulo ctr for hard check
                j read_page
done_bitstr:    jalr zero, 0(ra)
#check if the new page with instructions is ready
#call with a0=page_size a1=nr_pages
init_paging:    addi s0, zero, 0x80         #s0: start address of first page
                addi s1, s0, 0              #s1: start address of current page
                addi s2, zero, 0            #s2: page counter
                addi s3, s2, 0              #s3: page counter modulo  
paging:         addi s3, s3, 1
                addi s2, s2, 1
                add s1, s1, a0              #start_page += page_size
                bne s3, a1, poll_instr
                addi s3, zero, 0
                addi s1, s0, 0
poll_instr:     lw t0, 0x0(zero)
                bne t0, s2, poll_instr
next_page:      jalr zero, s1, 0            #move PC to start address of next page
                nop
                nop 
                nop
                nop
                nop
                nop
                nop
                nop
                nop
#### page 1 ####################################################################################################
#the values of s0, s1, s2 etc are preserved between pages (dont use them except for the paging)
req_next1:      lw t0, 0xc(zero)            #read page request counter
                addi t0, t0, 1              #increment page request counter 
                sw t0, 0xc(zero)            #store new page request counter
main1:          jal ra, deadbeef1
                nop                         #do stuff here
                lw a0, 0x4(zero)            #a0=page_size
                lw a1, 0x8(zero)            #a1=nr_pages                    
                jal zero, paging1
deadbeef1:      lui t0, 0xdeadc
                addi t0, t0, -273           #t0=deadbeef
                sw t0, 0x020(zero)          #mem[0x020]=deadbeef
                jalr zero, 0(ra)
#check if the new page with instructions is ready
#call with a0=page_size a1=nr_pages
paging1:        addi s3, s3, 1              #s3: page counter modulo++
                addi s2, s2, 1              #s2: page counter++ 
                add s1, s1, a0              #s1: start address of current page; start_page += page_size
                bne s3, a1, poll_instr1     #if modulo counter has reached last page, start at first page addr again and reset modulo counter
                addi s3, zero, 0
                addi s1, s0, 0
poll_instr1:    lw t0, 0x0(zero)
                bne t0, s2, poll_instr1
next_page1:     jalr zero, s1, 0            #move PC to start address of next page
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