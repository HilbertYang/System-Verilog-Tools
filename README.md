# SystemVerilog Learning, Practice, and Utility Modules

This repository collects SystemVerilog learning exercises, interview-style RTL
problems, and small reusable modules. Exercises cover arithmetic, streaming
interfaces, storage, control logic, clock-domain crossing, and state machines.

## What This Repo Is For

- Learning and reviewing SystemVerilog RTL design.
- Implementing interview problems and reviewing their behavior and timing.
- Practicing simulation and verification with the testbenches available in some directories.
- Developing small modules that can be adapted for larger designs.

## Repository Layout

| Path | Contents |
| --- | --- |
| [IP/](IP/) | RTL exercises and small IP modules; see the exercise index below. |
| [UVM/uart_uvm_tb/](UVM/uart_uvm_tb/README.md) | UART RTL, plain SystemVerilog testbenches, UVM components, and QuestaSim scripts. |
| [AGENTS.md](AGENTS.md) | Repository collaboration, problem-writing, and review conventions. |

An exercise directory may contain:

- `question.md` for newer problem statements, or `question.txt` for older ones.
- RTL implementation files such as `*.sv` or `*.v`.
- `tb_*.sv` testbenches and `*_golden.sv` reference implementations where available.
- Additional explanations, review notes, or simulation artifacts.

Not every exercise has a testbench or a reference implementation. An index entry
indicates that the exercise exists, not that its implementation has been fully
verified.

## Exercise Index

### Arithmetic and Datapaths

| Exercise | Focus | Problem statement |
| --- | --- | --- |
| [two_bit_full_adder](IP/two_bit_full_adder/) | Two-bit addition by instantiating one-bit full adders. | [Question](IP/two_bit_full_adder/question.txt) |
| [sixLaneSum_handshake](IP/sixLaneSum_handshake/) | Six-input summation with single-stage and two-stage valid/ready designs. | [Question](IP/sixLaneSum_handshake/question.txt) |
| [iterative_multiplier](IP/iterative_multiplier/) | Eight-cycle unsigned multiplication using shift-and-add operations. | [Question](IP/iterative_multiplier/question.txt) |
| [unsigned_divider](IP/unsigned_divider/) | Parameterized restoring division with quotient, remainder, and divide-by-zero handling. | [Question](IP/unsigned_divider/question.txt) |
| [divider_sum](IP/divider_sum/) | Computing `a/b + c/d + e/f` with resource-sharing and parallel pipeline architectures. | [Question](IP/divider_sum/question.txt) |
| [saturating_accumulator](IP/saturating_accumulator/) | Signed accumulation with saturation and clipping indication. | [Question](IP/saturating_accumulator/question.txt) |
| [moving_sum4](IP/moving_sum4/) | Running sum of the four most recently accepted samples. | [Question](IP/moving_sum4/question.txt) |

The unsigned divider also has a [datapath explanation and simulation instructions](IP/unsigned_divider/README.md).

### Streaming Interfaces and Packet Processing

| Exercise | Focus | Problem statement |
| --- | --- | --- |
| [one_stage_buffer](IP/one_stage_buffer/) | Single-entry valid/ready buffering with simultaneous consumption and replacement. | [Question](IP/one_stage_buffer/question.txt) |
| [stream_packer](IP/stream_packer/) | Packing four input bytes into one 32-bit output word under backpressure. | [Question](IP/stream_packer/question.txt) |
| [stream_broadcast2](IP/stream_broadcast2/) | Delivering each input byte once to two independently stalled outputs. | [Question](IP/stream_broadcast2/question.txt) |
| [packet_arbiter](IP/packet_arbiter/) | Merging two streams while retaining ownership through each packet. | [Question](IP/packet_arbiter/question.txt) |
| [packet_crc8](IP/packet_crc8/) | Byte-per-clock packet CRC-8 calculation with a buffered result and output backpressure. | [Question](IP/packet_crc8/question.md) |
| [byte_stream_parser](IP/byte_stream_parser/) | Detecting three consecutive SOP bytes, capturing a 16-byte payload, and checking pairwise parity. | [Reconstructed question and review](IP/byte_stream_parser/byte_stream_parser_question_review.md) |

The byte-stream parser document reconstructs an earlier problem and explicitly
identifies assumptions used to complete its specification.

### Storage and Associative Lookup

| Exercise | Focus | Problem statement |
| --- | --- | --- |
| [syn_fifo](IP/fifo/syn_fifo/) | Eight-entry synchronous FIFO with defined simultaneous read/write behavior. | [Question](IP/fifo/syn_fifo/question.txt) |
| [byte_write_ram](IP/byte_write_ram/) | Synchronous RAM with byte write enables and same-address read-before-write behavior. | [Question](IP/byte_write_ram/question.txt) |
| [assoc_table4](IP/assoc_table4/) | Four-entry key/data lookup with insertion, overwrite, deletion, and concurrent lookup/update operations. | [Question](IP/assoc_table4/question.md) |

### Control, Arbitration, Clocks, and Reset

| Exercise | Focus | Problem statement |
| --- | --- | --- |
| [rr_arbiter](IP/rr_arbiter/) | Four-request round-robin arbitration with priority advancement on accepted transfers. | [Question](IP/rr_arbiter/question.txt) |
| [interrupt_controller8](IP/interrupt_controller8/) | Pending interrupts, masking, event/clear priority, and fixed-priority encoding. | [Question](IP/interrupt_controller8/question.txt) |
| [watchdog_timer](IP/watchdog_timer/) | Programmable timeout intervals, kicks, and expiration reporting. | [Question](IP/watchdog_timer/question.txt) |
| [pwm_generator](IP/pwm_generator/) | Programmable PWM period and duty with configuration updates applied at frame boundaries and latest-request priority. | [Question](IP/pwm_generator/question.md) |
| [clk_divider](IP/clk_divider/) | Divide-by-two and divide-by-three clocks with 50% duty-cycle requirements. | [Question](IP/clk_divider/question.txt) |
| [asynSynreset](IP/asynSynreset/) | Asynchronous reset assertion and synchronous release. | [Question](IP/asynSynreset/question.txt) |
| [pulse_cdc_handshake](IP/pulse_cdc_handshake/) | Reliable event transfer across clock domains using request/acknowledgment synchronization. | [Question](IP/pulse_cdc_handshake/question.txt) |

### Finite-State Machines

| Exercise | Focus | Problem statement |
| --- | --- | --- |
| [traffic_light](IP/FSM/traffic_light/) | Moore FSM for a two-direction intersection traffic light controller. | [Question](IP/FSM/traffic_light/question.txt) |
| [vending_machine](IP/FSM/vending_machine/) | Moore FSM for coin handling, dispensing, and change. | [Question](IP/FSM/vending_machine/question.txt) |
| [seqDetection](IP/FSM/seqDetection/) | Moore FSM detecting overlapping occurrences of `1011`. | [Question](IP/FSM/seqDetection/question.txt) |
| [seqDetection_1001](IP/FSM/seqDetection_1001/) | Moore FSM detecting overlapping occurrences of `1001`. | [Question](IP/FSM/seqDetection_1001/question.txt) |

## Additional RTL and Verification Projects

| Project | Contents |
| --- | --- |
| [Asynchronous FIFO](IP/fifo/asy_fifo/) | RTL implementations; no dedicated problem statement is currently present. |
| [UART verification project](UVM/uart_uvm_tb/README.md) | Baud generation, TX/RX, controller loopback, and SV/UVM verification infrastructure. |

## How To Use It

For practice, choose a statement from the index and read its interface, reset,
acceptance conditions, and timing requirements before implementing the RTL. Use
an existing testbench when one is available, and check which DUT files and
dependencies it requires.

For reuse, inspect the implementation and its verification coverage before
adapting it to another design. Different exercises use different reset styles
and handshakes; the corresponding statement is the source for those details.

## Compilation and Simulation

Run the commands below from the repository root. Replace placeholders with the
actual top module and all required source files.

### Icarus Verilog

Compile-only check:

```bash
iverilog -g2012 -Wall -s <top_module> -t null <source_files>
```

Simulation example using the existing one-stage buffer testbench:

```bash
iverilog -g2012 -Wall -s tb_one_stage_buffer \
  -o /tmp/one_stage_buffer.vvp \
  IP/one_stage_buffer/one_stage_buffer.sv \
  IP/one_stage_buffer/tb_one_stage_buffer.sv
vvp /tmp/one_stage_buffer.vvp
```

Icarus does not support every SystemVerilog construct used here. For example,
unpacked array arguments to functions are unsupported in the installed Icarus
12.0 used during review of the associative table. Distinguish tool limitations
from RTL errors and use a supporting simulator when needed.

### Verilator

Static lint check:

```bash
verilator --lint-only -Wall --Wno-fatal \
  --top-module <top_module> <source_files>
```

Inspect the diagnostics as well as the exit status: `--Wno-fatal` allows warnings
without failing the command. Passing compilation or lint is separate from
passing functional simulation.

### ModelSim / QuestaSim

```bash
vlog -sv <source_files>
vsim -c work.<top_module> -do "run -all; quit"
```

For UART-specific filelists and run scripts, see the
[UART project README](UVM/uart_uvm_tb/README.md).
