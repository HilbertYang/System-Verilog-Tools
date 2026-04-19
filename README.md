# SystemVerilog Learning, Practice, and Utility Modules

This repository started as a personal workspace for learning SystemVerilog.
Later, it also became a place to collect interview-style RTL problems and small reusable modules.

Many folders include a `question.txt` file that describes the problem statement, and each problem usually has a matching testbench so it can be used directly for practice.
Several of these modules are also practical enough to be reused as small building blocks in real projects.

## What This Repo Is For

- learning and reviewing SystemVerilog RTL design
- practicing interview questions with runnable testbenches
- collecting small modules that can be reused in larger designs

## Repository Layout

Each topic is organized in its own folder. A typical folder may contain:

- implementation file such as `*.sv`
- `question.txt` with the problem description
- `tb_*.sv` testbench for simulation and verification
- `*_golden.sv` golden or reference implementation in some directories

Current topics in the repository include:

- `one_stage_buffer/`: single-stage valid/ready buffer
- `sixLaneSum_handshake/`: handshake-based multi-input sum modules
- `asynSynreset/`: async reset, sync release style logic
- `fifo/`: FIFO-related exercises and utilities
- `FSM/`: finite-state-machine practice problems
- `two_bit_full_adder/`: basic combinational design practice
- `clk_divider/`: clock divider examples

## How To Use It

You can use this repository in two different ways:

1. As a practice set:
   read `question.txt`, implement the module yourself, then run the matching testbench.
2. As a utility collection:
   take the small modules as references or directly adapt them into other RTL projects.

## Simulation

### Icarus Verilog

```bash
iverilog -g2012 -o sim.vvp <design>.sv <testbench>.sv
vvp sim.vvp
```

Example:

```bash
iverilog -g2012 -o sim.vvp one_stage_buffer/one_stage_buffer.sv one_stage_buffer/tb_one_stage_buffer.sv
vvp sim.vvp
```

### ModelSim / QuestaSim

```bash
vlog <design>.sv <testbench>.sv
vsim -c work.<top_module> -do "run -all; quit"
```

## Notes

- `question.txt` is an important part of this repo. It records many interview-oriented design exercises collected during interview preparation.
- Most practice problems have corresponding testbenches, so they are suitable for hands-on drills rather than just reading.
- Some modules are intentionally small and focused, which also makes them convenient to reuse as real project utilities.
