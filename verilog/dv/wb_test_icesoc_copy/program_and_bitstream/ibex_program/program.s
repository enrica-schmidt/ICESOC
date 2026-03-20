#written by Enrica for SRAM paging
main:           addi x8, x0, 128 # x0/s0=128 start address of current page
                addi x9, x0, 1 # x9/s1=1 (expected "counter" value if next page is loaded, toggles 0/1)

#write deadbeef to address 0x004 to pass test
                lui t0, 0xdeadc
                addi t0, t0, -273 #t0=deadbeef
                sw t0, 0x004(x0) #mem[0x004]=deadbeef

#read bitstream from sram and configure efpga with it
read_bitstream: addi s2, x0, 1152
                addi s3, x0, 1
read_page:      addi s4, s2, 0
config:         lw t1, 0(s4)
                nop #substitute with custom instruction eFPGA3d0 x0, x6, x0=0003300b later to write contents of x6 to efpga config (SelfWriteData)
                addi s4, s4,  4
                addi t1, s2, 256
                blt s4, t1, config
poll:           lw t0, 1024(x0)
                bne t0, s3, poll
                xori s3, s3, 1
                bne s3, x0, page2
                addi s2, s2, 256
                j next
page2:          addi s2, s2, -256
next:           j read_page

poll_ctr:       lw t0, 0(x0)
                bne t0, s1, poll_ctr
                xori s1, s1, 1
                bne s1, x0, page2_mem
                addi s0, s0, 256
                j next_mem

page2_mem:      addi s0, s0, -256
next_mem:       jalr x0, s0, 0
