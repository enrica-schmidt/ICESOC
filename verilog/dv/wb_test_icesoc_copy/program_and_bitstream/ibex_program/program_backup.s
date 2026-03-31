#written by Enrica for SRAM paging
main:           addi s0, zero, 128      #s0: start address of current page
                addi s1, zero, 1        #s1: expected "counter" value if next page is loaded, (toggles 0/1)

#write deadbeef to address 0x004 to pass test
                lui t0, 0xdeadc
                addi t0, t0, -273       #t0=deadbeef
                sw t0, 0x004(zero)      #mem[0x004]=deadbeef

#read bitstream from sram and configure efpga with it
read_bitstream: addi s5, zero, 0        #s5: count the bitstream words that have been read from sram
                addi s2, zero, 1152     #s2: start of current bitstream page
                addi s3, zero, 1        #s3: expected "counter" value 
read_page:      addi s4, s2, 0          #s4: current read address (bitstream data)
config:         
                lw t1, 0(s4)
                nop #substitute with custom instruction eFPGA3d0 zero, t1, zero=0003300b later to write contents of t1 to efpga config (SelfWriteData)
                addi s4, s4, 4
                addi t1, s2, 256
                blt s4, t1, config
poll:           lw t0, 1024(zero)
                bne t0, s3, poll
                xori s3, s3, 1
                bne s3, zero, page2
                addi s2, s2, 256
                j next
page2:          addi s2, s2, -256
next:           j read_page



poll_ctr:       lw t0, 0(zero)
                bne t0, s1, poll_ctr
                xori s1, s1, 1
                bne s1, zero, page2_mem
                addi s0, s0, 256
                j next_mem

page2_mem:      addi s0, s0, -256
next_mem:       jalr zero, s0, 0
    
