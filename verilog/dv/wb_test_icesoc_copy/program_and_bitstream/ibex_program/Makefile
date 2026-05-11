TARGET = program

.PHONY: all clean

all: 
	$(MAKE) clean
	$(MAKE) $(TARGET).hex $(TARGET).h $(TARGET).disasm

%.elf: %.s
	riscv64-unknown-elf-gcc -march=rv32im -mabi=ilp32 -nostdlib -static -Wl,-Ttext=0x0 -o $@ $<

%.bin: %.elf
	riscv64-unknown-elf-objcopy -O binary $< $@

%.hex: %.bin
#need to escape the $ with $$ for the sed command
	hexdump -v -e '1/4 "%08x"' $< | sed 's/../&\n/g' | sed '/^$$/d' > $@ 
#this was generating a hex file with one byte per line and the lsb first

#substitute all nop instructions with the custom instruction 000ff00b, the nice solution would be to modify the compiler to recognize custom instructions, but this is sufficient for now
#perl -0777 -i -pe 's/00\n00\n00\n13/00\n0f\nf0\n0b/g' program.hex
#substitute only the first occurrence of nop with the custom instruction 
	perl -0777 -i -pe 's/00\n00\n00\n13/00\n0f\nf0\n0b/' program.hex
#%.h: %.bin

#	hexdump -v -e '1/4 "0x%08x,\n"' $< > $@
# modify this accordingly perl -0777 -i -pe 's/00\n00\n00\n13/00\n0f\nf0\n0b/' program.hex
#	perl -0777 -i -pe 's/0x00000013/000ff00b/' program.h

%.h: %.bin
	@echo "volatile static const uint32_t instructions[] = {" > $@
	@hexdump -v -e '1/4 "    0x%08x,\n"' $< >> $@
	@sed -i '$${s/,//}' $@
	@echo "};" >> $@
	@perl -0777 -i -pe 's/0x00000013/0x000ff00b/' $@


%.disasm: %.elf
	riscv64-unknown-elf-objdump -d $< > $@

clean:
	rm -f *.elf *.bin *.hex *.disasm *.h