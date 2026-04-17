# SystemVerilog Learning Notes

This repository collects small SystemVerilog RTL exercises and interview-style practice problems.
The current focus is valid/ready handshake design, small buffering modules, and simple datapath implementations that are easy to simulate with Icarus Verilog.

## Repository Structure

```text
System-Verilog-Tools/
├── one_stage_buffer/
│   ├── one_stage_buffer.sv
│   ├── tb_one_stage_buffer.sv
│   └── question.txt
├── sixLaneSum_handshake/
│   ├── sixLaneSum_handshake.sv
│   ├── sixLaneSum_handshake_pipe2.sv
│   ├── tb_sixLaneSum_handshake.sv
│   └── question.txt
├── clk_divider/
│   └── clk_divider.v
├── README.md
└── CLAUDE.md
```

## Directory Guide

### `one_stage_buffer/`

Single-entry buffer with `valid/ready` handshake.

- `one_stage_buffer.sv`: reference 1-stage buffer implementation
- `tb_one_stage_buffer.sv`: simulation testbench
- `question.txt`: interview prompt in Chinese and English

Key behavior:
- accepts new data only on `in_valid && in_ready`
- releases data only on `out_valid && out_ready`
- supports same-cycle dequeue + enqueue

### `sixLaneSum_handshake/`

Handshake-wrapped six-input 32-bit adder.

- `sixLaneSum_handshake.sv`: single-cycle version
- `sixLaneSum_handshake_pipe2.sv`: two-stage pipeline version
- `tb_sixLaneSum_handshake.sv`: handshake-oriented testbench
- `question.txt`: interview prompt in Chinese and English

Key behavior:
- six 32-bit inputs are accepted as one transaction
- output is held with `out_valid` until downstream handshakes
- back-to-back transfers are supported through `in_ready` / `out_ready` logic

### `clk_divider/`

Clock divider examples, including:
- even divider
- odd divider
- generic wrapper divider

## Simulation

### Icarus Verilog

```bash
# one-stage buffer
iverilog -g2012 -o sim.vvp one_stage_buffer/one_stage_buffer.sv one_stage_buffer/tb_one_stage_buffer.sv
vvp sim.vvp

# six-lane handshake adder
iverilog -g2012 -o sim.vvp sixLaneSum_handshake/sixLaneSum_handshake.sv sixLaneSum_handshake/tb_sixLaneSum_handshake.sv
vvp sim.vvp

# generic pattern
iverilog -g2012 -o sim.vvp <design>.sv <testbench>.sv
vvp sim.vvp
```

### ModelSim / QuestaSim

```bash
vlog <design>.sv <testbench>.sv
vsim -c work.<top_module> -do "run -all; quit"
```

## Notes

- `question.txt` files are kept as interview-style design prompts.
- The current handshake modules use helper signals such as `in_hs` and `out_hs` to mark completed transfers.
- Generated files such as `*.vvp` are local simulation artifacts and not part of the design source.
