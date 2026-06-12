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

#locally: export PDK_ROOT=~/Uni/studienarbeit/tools_icesoc/pdks
#locally: export GCC_PREFIX=riscv64-unknown-elf

#epic:    export PDK_ROOT=/scratch/tn312
#epic:    export GCC_PATH=/scratch/tn312/xpack-riscv-none-elf-gcc-15.2.0-1/bin/
#epic:    export GCC_PREFIX=riscv-none-elf

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
UPRJ_RTL_EFPGACORE = $(UPRJ_VERILOG_PATH)/rtl/eFPGA_core
UPRJ_RTL_EFPGACONF = $(UPRJ_VERILOG_PATH)/rtl/eFPGA_conf

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
SIM_DEFINES = -DFUNCTIONAL -DSIM
SIM?=RTL

.SUFFIXES:

PATTERN = wb_test_icesoc

all:  
	$(MAKE) clean 
	$(MAKE) ${PATTERN:=.fst} 
	$(MAKE) clean_without_fst
#	$(MAKE) ${PATTERN:=.disasm} 

hex:  ${PATTERN:=.hex}

%.vvp: %_tb.v %.hex
ifeq ($(SIM),RTL)
	iverilog $(SIM_DEFINES) -I $(PDK_PATH) \
	-I $(CARAVEL_BEHAVIOURAL_MODELS) -I $(CARAVEL_RTL_PATH) -I $(UPRJ_BEHAVIOURAL_MODELS) \
	-I $(UPRJ_RTL_PATH) \
	-I $(UPRJ_RTL_ICESOC) \
	-I $(UPRJ_RTL_IBEXCORE) \
	-I $(UPRJ_RTL_EFPGACORE) \
	-I $(UPRJ_RTL_EFPGACONF) \
	$(UPRJ_RTL_EFPGACONF)/*.v \
	$(UPRJ_RTL_EFPGACORE)/*.v \
	$(UPRJ_RTL_PATH)/models_pack.v \
	$< -o $@ -g2012
else
	iverilog $(SIM_DEFINES) -DGL -I $(PDK_PATH) \
	-I $(CARAVEL_BEHAVIOURAL_MODELS) -I $(CARAVEL_RTL_PATH) -I $(CARAVEL_VERILOG_PATH) \
	-I $(UPRJ_BEHAVIOURAL_MODELS) -I$(UPRJ_RTL_PATH)   -I $(UPRJ_VERILOG_PATH) \
	$< -o $@
endif

%.fst: %.vvp
	date
	vvp $< -fst

#ibex_prog = ./ibex_prog.h
#$(ibex_prog): ibex_prog/*.c
#	make -C ./ibex_prog all work_dir=build

#compile the program for ibex with the makefile in that folder, copy the header file generated in this directory, copy the bitstream.h file. then compile the firmware 
%.elf: %.c $(LDSCRIPT) ../riscv_firmware_src/crt0_vex.S check-env
	cd program_and_bitstream/ibex_program && $(MAKE) && cp program.h ../../memory.h && $(MAKE) clean
	cd program_and_bitstream/bitstream && python generate_header.py bitstr.hex bitstr.h && cp bitstr.h ../../bitstream.h && rm bitstr.h
	cd program_and_bitstream && cp instr_bitstr_sizes.h ../instr_bitstr_sizes.h
	${GCC_PATH}${GCC_PREFIX}-gcc $(INCLUDES) $(CFLAGS) $(LDFLAGS) -o $@ $(SRC_FILES) $<

%.disasm: %.elf
	${GCC_PATH}${GCC_PREFIX}-objdump -S -d $< > $@

%.hex: %.elf
	${GCC_PATH}${GCC_PREFIX}-objcopy -O verilog $< $@
	# to fix flash base address
	sed -i 's/@1000/@0000/g' $@

%.bin: %.elf
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
	rm -rf *.elf *.hex *.bin *.vvp *.vcd *.fst *.disasm *.log ibex_prog.h ibex_prog/build *.h

clean_without_fst:
	rm -rf *.elf *.hex *.bin *.vvp *.vcd *.disasm *.log ibex_prog.h ibex_prog/build memory.h bitstream.h

.PHONY: clean hex all clean_without_fst
