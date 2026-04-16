# SystemVerilog Learning Notes

This repository records my **SystemVerilog / verification learning process** during my spare time.

The goal is not to provide a complete tutorial, but to:
- build a solid understanding of SystemVerilog
- practice verification-oriented coding
- accumulate reusable RTL examples and testbenches
- form a long-term, traceable learning path

---

## Motivation

SystemVerilog is widely used in **digital IC design and verification**.  
Through this repository, I aim to strengthen my understanding of:

- SystemVerilog language features
- Testbench architecture concepts
- Verification-oriented thinking
- Coding style and best practices

---

## Repository Structure

```text
System-Verilog-Tools/
├── fifo/
│   ├── syn_fifo/          # Synchronous FIFO (single clock domain)
│   │   ├── sync_fifo.v    # Verilog implementation (DATA_WIDTH=8, DEPTH=16)
│   │   ├── sync_fifo.sv   # SystemVerilog implementation (DATA_WIDTH=64, DEPTH=16)
│   │   └── tb_synfifo.sv  # Testbench for the .sv version
│   └── asy_fifo/          # Asynchronous FIFO (dual clock domain)
│       ├── async_fifo.v   # Verilog implementation (combinational full/empty)
│       └── async_fifo.sv  # SystemVerilog implementation (registered full/empty, power-of-2 check)
└── clk_divider/
    └── clk_divider.v      # Even / odd / general clock dividers
```

---

## Module Descriptions

### Synchronous FIFO (`fifo/syn_fifo/`)

Single-clock FIFO with (ADDR_WIDTH+1)-bit pointers. The MSB acts as a wrap-around flag for full/empty detection.

- **full**: MSBs differ, lower address bits equal
- **empty**: pointers identical

Two implementations provided:
- `sync_fifo.v` — plain Verilog, `wire`/`reg` style
- `sync_fifo.sv` — SystemVerilog `logic`/`always_ff` style

### Asynchronous FIFO (`fifo/asy_fifo/`)

Dual-clock FIFO with Gray-code pointer synchronization across clock domains.

- Binary pointers are converted to Gray code before crossing via 2-FF synchronizers
- **empty**: compared in `rd_clk` domain (`rd_gray == wr_gray_sync2`)
- **full**: top two bits inverted, remaining bits equal (compared in `wr_clk` domain)

Two implementations provided:
- `async_fifo.v` — plain Verilog, combinational full/empty outputs
- `async_fifo.sv` — SystemVerilog, registered full/empty outputs with next-pointer logic; includes an `initial` check that `DEPTH` must be a power of 2

### Clock Dividers (`clk_divider/`)

Three modules in a single file:

| Module | Description |
|---|---|
| `clk_div_even` | Even division (N must be even), 50% duty cycle, posedge only |
| `clk_div_odd` | Odd division (N odd, ≥ 3), 50% duty cycle via dual pos/negedge counters |
| `clk_divider` | General wrapper; selects even or odd path via `generate` |

---

## Simulation

### Icarus Verilog

```bash
# Synchronous FIFO testbench
iverilog -g2012 -o sim.vvp fifo/syn_fifo/sync_fifo.sv fifo/syn_fifo/tb_synfifo.sv
vvp sim.vvp

# Generic flow
iverilog -o sim.out <design>.v <testbench>.v && vvp sim.out
```

### ModelSim / QuestaSim

```bash
vlog <design>.v <testbench>.v
vsim -c work.<top_module> -do "run -all; quit"
```

---

## Planned Additions

- `basics/` — language basics and small examples
- `oop/` — SystemVerilog OOP practice (class, inheritance, polymorphism)
- `testbench/` — structured testbench examples
- `uvm/` — UVM-related learning notes
