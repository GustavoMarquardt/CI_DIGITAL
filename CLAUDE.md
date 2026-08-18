# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

A RISC-V single-cycle processor written in Verilog, applied to an automotive ECU
(electronic control unit) for a single-cylinder combustion engine. The CPU reads
engine sensors (RPM, throttle, temperatures, MAP, TDC) over memory-mapped I/O and
drives actuators (ignition advance, injection time, ignition trigger, safety flags).
Documentation and code comments are in Portuguese.

## Two project trees — know which one you're in

- **`RISCSingleCicle-ECU/ProjetoFinal/`** — the active project. Adds memory-mapped I/O
  (`io_controller.v`, `sensor_simulator.v`), the ignition lookup table, the Python
  assembler, and the automotive testbenches. **Make changes here.**
- **`ProjetoRISCSingleCicle-Full-Single-Cycle/ProjetoFinal/`** — the original bare
  RISC-V single-cycle CPU it was forked from (no I/O, no ECU logic). Historical
  baseline; generally leave untouched.

Note: the Verilog modules directory is named **`módulos`** (with accent) on disk.

## Toolchain: Icarus Verilog (not ModelSim)

The READMEs/QUICK_START describe ModelSim `vlog`/`vsim` — **ignore that**. The real
build path is **Icarus Verilog** (`iverilog -g2012` + `vvp`), as used by the run
scripts and reflected by the `.vvp` artifacts in the tree. The scripts auto-discover
iverilog in `C:\iverilog\bin`, `C:\iverilog`, the `IVL_ROOT` env var, or `PATH`.

### Build & run the full automotive testbench

From `RISCSingleCicle-ECU/ProjetoFinal/`:

```powershell
./run_ecu_tests.ps1        # or run_ecu_tests.cmd
```

This compiles every `módulos/*.v` plus `testbenches/ecu_automotive_tb.v` into
`ecu_automotive_run.vvp`, runs it, and writes all output to `ecu_automotive_test.log`
(overwritten each run; last 35 lines echoed to console). A passing run shows `✓ PASS`
lines across the 6 scenarios; `FAIL`/`✗` indicates a regression.

### Build & run any other testbench manually

```powershell
iverilog -g2012 -o sim.vvp módulos/*.v testbenches/<some_tb>.v
vvp sim.vvp
```

Single-module testbenches live in `testbenches/submodulos/` (e.g. `ALU_tb.v`,
`register_file_tb.v`); compile the module(s) under test plus its `_tb.v`.

## Assembler workflow (assembly → instruction memory)

Programs in `programs/*.asm` are not loaded at simulation time. They must be assembled
into a Verilog fragment and pasted into `módulos/instruction_memory.v`:

```powershell
python tools/assembler.py programs/ecu_control.asm programs/imem_generated.v
```

The assembler is two-pass (resolves labels), emits 32-bit machine code, and supports
ADD, SUB, MUL, DIV, AND, OR, SLT, ADDI, ANDI, LW, SW, BEQ, BNE, BLT, BGE, JAL.
`tools/lookup_table_generator.py` similarly generates the 8×8 ignition table fragment
for the `initial` block of `data_memory.v`.

## Architecture

`cpu.v` is the top module. It wires `Control_Unit` to three datapath slices — this
split is the main thing to understand before editing the core:

- **`datapath1`** — PC, instruction fetch, and the register file (`Result` write-back).
- **`datapath2`** — execute + memory: ALU, `data_memory`, **and `io_controller`**.
  This is where sensor inputs and actuator outputs are threaded through.
- **`datapath3`** — immediate generation (`SignExtend`/`ImmSrc`) and branch/jump
  target computation.

### Memory-mapped I/O routing (the critical detail)

In `datapath2.v`, the ALU result address decides whether a load/store hits RAM or I/O:

- `io_select = (ALUResult >= 0x1000)` — any address ≥ `0x1000` routes to `io_controller`.
- `0x0000–0x0FFF` is `data_memory` (includes the ignition lookup table at words 64–127).
- Writes fan out via `mem_write_enable`/`io_write_enable`; reads mux on `io_select`.

I/O address map: sensors (read-only) at `0x1000` (RPM), `0x1004` (TPS), `0x1008`
(temp motor), `0x100C` (temp air), `0x1010` (MAP), `0x1014` (TDC); actuators at
`0x2000` (advance), `0x2004` (injection time), `0x2008` (trigger), `0x2010` (safety
flags). See `docs/memory_map.md`.

### Project-specific ALU encoding

`ALUControl` is a custom 3-bit code (not standard RISC-V funct), decoded in
`ULA_Decoder.v`: MUL = `3'b100`, DIV = `3'b110`, MOD = `3'b111`. DIV-by-zero returns
`0xFFFFFFFF`, MOD-by-zero returns `0`. Branch type is selected by `funct3[0]`
(`Branch_type`): BEQ when 0, BNE when 1, combined into `PCSrc` in `Control_Unit.v`.

When adding an instruction you typically touch four files in concert: `ALU.v`
(operation), `ULA_Decoder.v` (ALUControl mapping), `Main_Decoder.v` (opcode → control
signals), and `tools/assembler.py` (encoding) — plus the relevant testbench.

## Reference docs

`docs/ISA_reference.md` (instruction set & formats), `docs/memory_map.md` (full
address map), `docs/automotive_algorithms.md` (ignition/injection/safety algorithms).
