# SPDX-FileCopyrightText: 2020 Efabless Corporation
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# SPDX-License-Identifier: Apache-2.0

## PDK

include environment_vars.txt 

PDK_PATH = $(PDK_ROOT)/sky130A

## Caravel Pointers
CARAVEL_ROOT ?= ../../../caravel
CARAVEL_PATH ?= $(CARAVEL_ROOT)
CARAVEL_FIRMWARE_PATH = $(CARAVEL_PATH)/verilog/dv/caravel
CARAVEL_VERILOG_PATH  = $(CARAVEL_PATH)/verilog
CARAVEL_RTL_PATH = $(CARAVEL_VERILOG_PATH)/rtl
CARAVEL_BEHAVIOURAL_MODELS = $(CARAVEL_VERILOG_PATH)/dv/caravel

## User Project Pointers
UPRJ_VERILOG_PATH ?= ../../../verilog
UPRJ_BEHAVIOURAL_MODELS = ../
UPRJ_RTL_PATH      = $(UPRJ_VERILOG_PATH)/rtl
UPRJ_RTL_ICESOC    = $(UPRJ_VERILOG_PATH)/rtl/icesoc
UPRJ_RTL_IBEXCORE  = $(UPRJ_VERILOG_PATH)/rtl/ibex_core
UPRJ_RTL_EFPGA     = $(shell find $(UPRJ_VERILOG_PATH)/rtl/eFPGA -type d)
#Gemini:
# Find all subdirectories inside eFPGA
EFPGA_DIRS = $(shell find $(UPRJ_RTL_EFPGA) -type d)

# Add '-I' for `include statements
EFPGA_INCLUDES = $(addprefix -I , $(EFPGA_DIRS))

# Add '-y' so iverilog automatically searches these folders for missing modules
EFPGA_LIBS = $(addprefix -y , $(EFPGA_DIRS))

EFPGA_SRCS = $(UPRJ_RTL_EFPGA)/eFPGA.v
# UPRJ_RTL_EFPGACONF = $(UPRJ_VERILOG_PATH)/rtl/eFPGA_conf


SRC_FILES := \
	../riscv_firmware_src/crt0_vex.S \
	../riscv_firmware_src/isr.c \
	../riscv_firmware_src/send_packet.c \
	../riscv_firmware_src/gpio_config_io.c \

# Definitions related to firmware creation
INCLUDES := \
		-I ../riscv_firmware_src/ \
		-I .

CFLAGS := -Os -Wall -Wpedantic -g -mabi=ilp32 -march=rv32i_zicsr -D__vexriscv__ -ffreestanding -nostdlib
LDSCRIPT := ../riscv_firmware_src/sections.lds
LDFLAGS := -Wl,-Bstatic,-T,$(LDSCRIPT)

## RISCV GCC
GCC_PATH?=
#GCC_PREFIX=

## Simulation mode: RTL/GL
SIM_DEFINES = -DFUNCTIONAL -DSIM -DEMULATION
SIM?=RTL

BITSTR_DIR = bitstreams
DESIGN = top

.SUFFIXES:
.SECONDARY: $(RUN_DIR)/%.elf $(RUN_DIR)/%.hex

PATTERN ?= wb_test_icesoc
RUN_DIR ?= output_dir

all:  
#	$(MAKE) clean 
#	mkdir -p $(RUN_DIR)
	mkdir -p $(RUN_DIR)/sources
	cp wb_test_icesoc.c $(RUN_DIR)/sources
	cp wb_test_icesoc_tb.v $(RUN_DIR)/sources
	cp instr_bitstr_sizes.h $(RUN_DIR)/sources
	$(MAKE) ${RUN_DIR}/${PATTERN:=.disasm} 2>&1 | tee $(RUN_DIR)/simulation.log
	$(MAKE) ${RUN_DIR}/${PATTERN:=.fst} 2>&1 | tee $(RUN_DIR)/simulation.log
#	$(MAKE) clean_without_fst
	

hex:  ${RUN_DIR}/${PATTERN:=.hex}

$(RUN_DIR)/%.vvp: $(RUN_DIR)/sources/%_tb.v $(RUN_DIR)/%.hex
ifeq ($(SIM),RTL)
	iverilog $(SIM_DEFINES) -I $(PDK_PATH) \
	-I $(CARAVEL_BEHAVIOURAL_MODELS) -I $(CARAVEL_RTL_PATH) -I $(UPRJ_BEHAVIOURAL_MODELS) \
	-I $(UPRJ_RTL_PATH) \
	-I $(UPRJ_RTL_ICESOC) \
	-I $(UPRJ_RTL_IBEXCORE) \
	$(EFPGA_INCLUDES) \
	${BITSTR_DIR}/${DESIGN}.vh \
	$(EFPGA_LIBS) \
	$(EFPGA_SRCS) \
	$(UPRJ_RTL_PATH)/eFPGA/Fabric/models_pack.v \
	$(UPRJ_RTL_PATH)/eFPGA/Tile/DSP/DSP_bot/DSP_bot_tile.v \
	$(UPRJ_RTL_PATH)/eFPGA/Tile/DSP/DSP_top/DSP_top_tile.v \
	$(UPRJ_RTL_PATH)/eFPGA/Frame_Select_Pack.v \
	$(UPRJ_RTL_PATH)/eFPGA/Frame_Data_Reg_Pack.v \
	$(UPRJ_RTL_PATH)/eFPGA/ConfigFSM.v \
	$(UPRJ_RTL_PATH)/eFPGA/Config.v \
	$(UPRJ_RTL_PATH)/eFPGA/config_UART.v \
	$(UPRJ_RTL_PATH)/eFPGA/bitbang.v \
	$< -o $@ -g2012
else
	iverilog $(SIM_DEFINES) -DGL -I $(PDK_PATH) \
	-I $(CARAVEL_BEHAVIOURAL_MODELS) -I $(CARAVEL_RTL_PATH) -I $(CARAVEL_VERILOG_PATH) \
	-I $(UPRJ_BEHAVIOURAL_MODELS) -I$(UPRJ_RTL_PATH)   -I $(UPRJ_VERILOG_PATH) \
	$< -o $@
endif

$(RUN_DIR)/%.fst: $(RUN_DIR)/%.vvp
	date
	cd $(RUN_DIR) && time vvp $(notdir $<) -fst

#ibex_prog = ./ibex_prog.h
#$(ibex_prog): ibex_prog/*.c
#	make -C ./ibex_prog all work_dir=build

#compile the program for ibex with the makefile in that folder, copy the header file generated in this directory, copy the bitstream.h file. then compile the firmware 
$(RUN_DIR)/%.elf: $(RUN_DIR)/sources/%.c $(LDSCRIPT) ../riscv_firmware_src/crt0_vex.S check-env
#	cd program_and_bitstream/ibex_program && $(MAKE) && cp program.h ../../memory.h && $(MAKE) clean
#	cd program_and_bitstream/bitstream && python generate_header.py bitstr.hex bitstr.h && cp bitstr.h ../../bitstream.h && rm bitstr.h
#	cd program_and_bitstream && cp instr_bitstr_sizes.h ../instr_bitstr_sizes.h
	${GCC_PATH}${GCC_PREFIX}-gcc $(INCLUDES) $(CFLAGS) $(LDFLAGS) -o $@ $(SRC_FILES) $<

$(RUN_DIR)/%.disasm: $(RUN_DIR)/%.elf
	${GCC_PATH}${GCC_PREFIX}-objdump -S -d $< > $@

$(RUN_DIR)/%.hex: $(RUN_DIR)/%.elf
	${GCC_PATH}${GCC_PREFIX}-objcopy -O verilog $< $@
	# to fix flash base address
	sed -i 's/@1000/@0000/g' $@

$(RUN_DIR)/%.bin: $(RUN_DIR)/%.elf
	${GCC_PATH}${GCC_PREFIX}-objcopy -O binary $< $@

# The compiler should either be located at a specific location or available as a global command
CC := $(or $(wildcard $(GCC_PATH)$(GCC_PREFIX)-gcc), $(shell which $(GCC_PREFIX)-gcc 2>/dev/null))

check-env:
ifndef PDK_ROOT
	$(error PDK_ROOT is undefined, please export it before running make)
endif
ifeq (,$(wildcard $(PDK_ROOT)/sky130A))
	$(error $(PDK_ROOT)/sky130A not found, please install pdk before running make)
endif
ifeq ($(CC),)
	$(error "Compiler not found in absolute path OR system PATH")
endif
# check for efabless style installation
ifeq (,$(wildcard $(PDK_ROOT)/sky130A/libs.ref/*/verilog))
SIM_DEFINES := ${SIM_DEFINES} -DEF_STYLE
endif

# ---- Clean ----

clean:
	rm -rf *.elf *.hex *.bin *.vvp *.vcd *.fst *.disasm *.log

clean_without_fst:
	rm -rf *.elf *.hex *.bin *.vvp *.vcd *.disasm *.log

.PHONY: clean hex all clean_without_fst
