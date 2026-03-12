INC_DIRS =
TARGET=minimal
SRCS = $(TARGET).c

OUTH    = ../ibex_prog.h
OUTBIN  = $(work_dir)/$(TARGET).bin
OUTPUT  = $(work_dir)/$(TARGET).elf
DISASM  = $(work_dir)/$(TARGET).disasm

GCC_PREFIX=riscv64-unknown-elf

all: $(OUTH) $(DISASM)

CCFLAGS+=-Os -march=rv32im -mabi=ilp32 -ffreestanding -nostartfiles -nostdlib -nodefaultlibs -fpic -Wl,-T link.ld crt.s -Wall -Wpedantic

$(OUTPUT) : $(SRCS)
	mkdir -p $(work_dir)
	${GCC_PATH}${GCC_PREFIX}-gcc  $^ $(CCFLAGS) $(INC_DIRS) -o $@

$(OUTBIN): $(OUTPUT)
	${GCC_PATH}${GCC_PREFIX}-objcopy -O binary $< $@

$(OUTH): $(OUTBIN)
	python3 gen_program.py $< $@

$(DISASM) : $(OUTPUT)
	${GCC_PATH}${GCC_PREFIX}-objdump -Dt $< > $@

clean:
	rm -rf $(work_dir)
.PHONY: clean
