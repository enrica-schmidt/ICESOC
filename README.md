# Caravel User Project

[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0) [![UPRJ_CI](https://github.com/efabless/caravel_project_example/actions/workflows/user_project_ci.yml/badge.svg)](https://github.com/efabless/caravel_project_example/actions/workflows/user_project_ci.yml) [![Caravel Build](https://github.com/efabless/caravel_project_example/actions/workflows/caravel_build.yml/badge.svg)](https://github.com/efabless/caravel_project_example/actions/workflows/caravel_build.yml)

ICESOC is a Heterogeneous Multicore SoC, integrating a customised embedded FPGA fabric and two RISC-V cores dedecating for Cryptographical applications. 

   <p align="center">
   <img src="./docs/source/ICESOC.png" width="50%" height="50%">
   </p>

# Study Project Enrica Schmidt
The study project titled "Reconfigurable Custom Instruction Set Extensions for RISC-V", which was finished on august 17, 2026, is based on this repo.
The report is included here as "Enrica_Schmidt_study_project.pdf".
The branch study_project_enrica_schmidt contains the folder verilog/dv/paging, which was initially a copy of wb_test_icesoc.
The paging folder was adapted to contain the paging functionality implemented in the scope of the study project, as well as the CRC application.
A README explaining how to use it is located inside the verilog/dv/paging folder.
The branch shrunk_fabric included a different fabric that was shrunk compared to the original fabric, to test the configuration first before testing on the original fabric. 
The repo at 
git@github.com:IAmMarcelJung/ICESOC_FABulous_user_project.git
can be used to generate the bitstream for the fabric, as explained in the README in verilog/dv/paging.