# UART UVM Testbench Project

This project is a learning workspace for building a UART RTL design first, then
verifying it with SystemVerilog and UVM on QuestaSim.

## Current Scope

- `rtl/uart_baud_gen.sv`: baud tick generator
- `rtl/uart_tx.sv`: UART transmitter
- `rtl/uart_rx.sv`: UART receiver
- `rtl/uart_controller.sv`: top-level UART controller skeleton
- `tb_sv/tb_uart_baud_gen.sv`: simple SystemVerilog testbench for the baud generator
- `tb_sv/tb_uart_tx.sv`: simple SystemVerilog testbench for TX
- `tb_sv/tb_uart_rx.sv`: simple SystemVerilog testbench for RX

The current milestone is to verify the baud generator, TX, and RX with plain SV
testbenches before moving on to the UVM environment.

The baud generator provides both a 1x `baud_tick` for TX bit transitions and a
16x `sample_tick` for RX oversampling. The RX samples the start bit near its
center, then samples each data/stop bit once per bit period.

## Directory Layout

```text
uart_uvm_tb/
├─ rtl/       # UART RTL modules
├─ tb_sv/     # plain SystemVerilog testbenches
├─ tb_uvm/    # future UVM verification components
└─ sim/       # QuestaSim filelists and run scripts
```

## Run Plain SV Simulation

From the `sim` directory:

```powershell
cd UVM\uart_uvm_tb\sim
vsim -do run_sv.do
```

For command-line mode:

```powershell
vsim -c -do "do run_sv.do; quit"
```

`sim/filelist_sv.f` lists the files compiled for the current plain SV
simulation. Update it when switching from the baud generator test to TX/RX tests.

Dedicated TX/RX scripts are also available:

```powershell
vsim -do run_tx.do
vsim -do run_rx.do
```
