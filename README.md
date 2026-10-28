# RV32I Microarchitecture & Verification Pipeline

A synthesizable, 32-bit RISC-V (RV32I base integer ISA) processor pipeline designed in Verilog HDL, verified via cycle-accurate simulation testbenches, and configured for FPGA synthesis.

## Architecture Overview
- **Instruction Set:** RV32I (Base Integer Instruction Set)
- **Supported Formats:** R-type, I-type, S-type, B-type, U-type, J-type
- **Datapath Features:** Dual-read/single-write register file (with x0 hardwired to 0), sign-extended immediate generation, 32-bit arithmetic logic unit (ALU), and pipeline control logic.
- **Verification Stack:** Directed and randomized testbenches using Icarus Verilog, GTKWave, and Verilator (lint clean).

## Repository Layout
- `rtl/` : Synthesizable Verilog RTL source files and defines
- `sim/` : Self-checking simulation testbenches
- `docs/`: Architecture specifications, diagrams, and waveforms
- `scripts/`: Automation and simulation helper scripts

## Toolchain
- **Simulator:** Icarus Verilog (`iverilog`) / Verilator
- **Waveform Viewer:** GTKWave
- **Synthesis:** Xilinx Vivado WebPACK / Yosys
- **Target OS:** Ubuntu Linux
