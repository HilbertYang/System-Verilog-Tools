# SystemVerilog Learning Notes

This repository tracks a personal SystemVerilog / digital design learning path.
It mixes small RTL exercises, handwritten practice, reference implementations,
and simple testbenches that can be simulated with Icarus Verilog.

The current focus is on:
- FSM coding style and sequence detection
- valid/ready handshake design
- small buffering and datapath exercises
- classic building blocks such as FIFOs and clock dividers

## Repository Structure

```text
System-Verilog-Tools/
├── FSM/
│   ├── question.txt                         # Chinese + English interview prompt
│   ├── seq_detection.sv                    # Moore FSM for sequence 1101
│   ├── seq_detection_mealy.sv              # Mealy FSM version
│   ├── hand_write_mealy_version_seq_dectioin.sv
│   ├── tb_seq_detection.sv
│   └── tb_seq_detection_mealy.sv
├── one_stage_buffer/
│   ├── question.txt                        # Chinese + English interview prompt
│   ├── one_stage_buffer.sv                 # Reference 1-stage buffer
│   ├── handwrite_one_stage_buffer.sv       # Handwritten practice version
│   └── tb_one_stage_buffer.sv
├── sixLaneSum_handshake/
│   ├── question.txt                        # Chinese + English interview prompt
│   ├── sixLaneSum_handshake.sv             # Reference handshake adder
│   ├── handwrite.sv                        # Handwritten practice version
│   ├── handwrite_pipe2.sv                  # Pipeline-oriented handwritten variant
│   └── tb_sixLaneSum_handshake.sv
├── fifo/
│   ├── syn_fifo/
│   │   ├── sync_fifo.v
│   │   ├── sync_fifo.sv
│   │   └── tb_synfifo.sv
│   └── asy_fifo/
│       ├── async_fifo.v
│       └── async_fifo.sv
├── clk_divider/
│   └── clk_divider.v
├── CLAUDE.md
└── README.md
```

## Directory Guide

### `FSM/`

Sequence detector practice centered on detecting `1101`.

- `seq_detection.sv`: Moore FSM, 3-segment style, overlap-aware
- `seq_detection_mealy.sv`: Mealy version with fewer states
- `hand_write_mealy_version_seq_dectioin.sv`: handwritten exercise file
- `question.txt`: interview-style prompt in Chinese and English

### `one_stage_buffer/`

Single-entry valid/ready buffer practice.

- `one_stage_buffer.sv`: reference implementation
- `handwrite_one_stage_buffer.sv`: handwritten practice version
- `tb_one_stage_buffer.sv`: basic handshake / back-pressure testbench
- `question.txt`: interview-style prompt in Chinese and English

### `sixLaneSum_handshake/`

Six-input 32-bit summation module wrapped in valid/ready handshake logic.

- `sixLaneSum_handshake.sv`: reference implementation
- `handwrite.sv`: handwritten version
- `handwrite_pipe2.sv`: pipelined variant exploration
- `tb_sixLaneSum_handshake.sv`: functional handshake testbench
- `question.txt`: interview-style prompt in Chinese and English

### `fifo/`

Classic FIFO exercises kept as reusable reference designs.

- `syn_fifo/`: single-clock FIFO in both Verilog and SystemVerilog
- `asy_fifo/`: dual-clock FIFO using Gray-code pointer synchronization

### `clk_divider/`

Clock divider exercises including even divide, odd divide, and a generic wrapper.

## Module Notes

### FSM sequence detectors

- Input interface: `clk`, `rst_n`, `din`
- Output: `match`
- Covers overlap handling for the `1101` sequence
- Includes both Moore and Mealy implementations for comparison

### One-stage buffer

- Single 32-bit storage element between upstream and downstream
- Uses `in_valid/in_ready` and `out_valid/out_ready`
- Supports same-cycle dequeue + enqueue behavior

### Six-lane handshake adder

- Accepts six 32-bit inputs in one transaction
- Produces one 32-bit sum under valid/ready flow control
- Includes a back-to-back transfer path when output is consumed and new input arrives in the same cycle

### FIFOs

- Sync FIFO: pointer-based full/empty detection in one clock domain
- Async FIFO: Gray-code pointers plus 2-FF synchronizers across clock domains

### Clock dividers

- `clk_div_even`: even divide with 50% duty cycle
- `clk_div_odd`: odd divide with posedge/negedge support
- `clk_divider`: generate-based wrapper that selects the proper implementation

## Simulation

### Icarus Verilog

```bash
# FSM Moore version
iverilog -g2012 -o sim.vvp FSM/seq_detection.sv FSM/tb_seq_detection.sv
vvp sim.vvp

# FSM Mealy version
iverilog -g2012 -o sim.vvp FSM/seq_detection_mealy.sv FSM/tb_seq_detection_mealy.sv
vvp sim.vvp

# One-stage buffer
iverilog -g2012 -o sim.vvp one_stage_buffer/one_stage_buffer.sv one_stage_buffer/tb_one_stage_buffer.sv
vvp sim.vvp

# Six-lane handshake adder
iverilog -g2012 -o sim.vvp sixLaneSum_handshake/sixLaneSum_handshake.sv sixLaneSum_handshake/tb_sixLaneSum_handshake.sv
vvp sim.vvp

# Generic pattern
iverilog -g2012 -o sim.vvp <design>.sv <testbench>.sv
vvp sim.vvp
```

### ModelSim / QuestaSim

```bash
vlog <design>.sv <testbench>.sv
vsim -c work.<top_module> -do "run -all; quit"
```

## Notes

- `question.txt` files are used as interview-style design prompts.
- Handwritten files are kept alongside cleaned-up reference versions on purpose.
- Generated outputs such as `*.vvp` and `*.vcd` are not intended to be committed.
