# SystemVerilog Interview Problem: 8-Bit SPI Mode 0 Master

Design a synthesizable master that transmits and receives one 8-bit byte during each transaction. This exercise uses the explicitly defined SPI Mode 0 timing below: the serial clock idles low, data is sampled on its rising transitions, and subsequent transmit bits are presented on its falling transitions.

## Interface

```systemverilog
module spi_master8 (
    input  logic       clk,
    input  logic       rst_n,

    input  logic       start,
    input  logic [7:0] tx_data,
    input  logic [7:0] cfg_half_period,

    output logic       busy,
    output logic       done,
    output logic [7:0] rx_data,

    output logic       sclk,
    output logic       cs_n,
    output logic       mosi,
    input  logic       miso
);
```

`clk` is the internal system clock. `sclk` is the generated serial-clock output; `cs_n` is an active-low transaction-select output. `mosi` carries transmitted bits and `miso` carries received bits. `start`, `tx_data`, and `cfg_half_period` are synchronous to `clk`.

## Clocking and Input Assumptions

- All internal state must update only on rising edges of `clk`. Generate `sclk` as an output signal; do not use `sclk` as the clock of another sequential process inside the module.
- All output ports must be registered. Their changes become visible after the relevant `clk` edge's register updates.
- Assume an ideal external device that presents each MISO bit before the internal `clk` edge that generates the corresponding rising transition of `sclk`. The bit remains stable through that sampling edge.
- Sample the **pre-edge value of `miso`** on that internal edge. The generated `sclk` rising transition becomes visible after that same edge. No input synchronizer or physical I/O timing analysis is required for this exercise.
- The external device may prepare the next MISO bit after a falling transition of `sclk`; it must not wait until the corresponding rising transition to prepare it.

## Reset and Idle State

- Use an **active-low synchronous reset**.
- On an edge with `rst_n=0`, cancel any transaction and set `busy=0`, `done=0`, `rx_data=0`, `sclk=0`, `cs_n=1`, and `mosi=0`.
- Reset overrides request acceptance, bit sampling, and completion on that edge.
- While idle and without accepting a request, keep `sclk=0`, `cs_n=1`, and `mosi=0`. Hold `rx_data` unchanged and clear `done` at the next edge after a completion.

## Request Acceptance and Configuration

- Accept a request at a rising edge of `clk` when the pre-edge values satisfy `start=1` and `busy=0`.
- On acceptance, capture `tx_data` and `cfg_half_period`. Later changes to those inputs must not affect the transaction.
- Define the captured half-period `H` as `cfg_half_period`, except that zero means `H=1`. Thus `H` is in the range 1 through 255, measured in internal clock periods.
- Immediately after the acceptance edge, set `busy=1`, clear `done`, assert `cs_n=0`, keep `sclk=0`, and present the captured transmit byte's bit 7 on `mosi`.
- Do not toggle `sclk` or sample `miso` on the acceptance edge.
- Ignore `start` whenever `busy=1` before a sampling edge. There is no request queue, and a request on the completion edge is also ignored.
- If `start` remains high, accept a fresh request at the next eligible idle edge, using the input byte and configuration present before that edge. Acceptance does not automatically lower the external `start` signal.

## Serial Transfer and Exact Timing

- Transmit and receive **most-significant bit first**, from bit 7 through bit 0. Receiving and transmitting happen concurrently.
- If the request is accepted at internal edge A, the first rising transition of `sclk` occurs after edge **A+H**, not A+H-1. The acceptance edge does not count as one elapsed clock period.
- Toggle `sclk` every `H` internal clock periods while the transaction is active. Both high and low serial-clock intervals last exactly `H` internal periods.
- On each of the eight generated rising transitions, sample one MISO bit. The first sampled bit becomes `rx_data[7]` in the final received byte, and the last becomes bit 0.
- Keep the current MOSI bit stable on each rising transition and throughout the following high interval.
- On the first seven falling transitions, present the next lower transmit bit on `mosi`. For example, the first falling transition changes MOSI from captured bit 7 to captured bit 6.
- The eighth rising transition samples the last MISO bit. Do **not** complete the transaction yet: preserve the final high interval for its full `H` internal periods.
- Complete on the eighth falling transition, after edge **A+16H**. After that edge, set `sclk=0`, `cs_n=1`, `mosi=0`, `busy=0`, and `done=1`, and update `rx_data` with the complete received byte.
- Exactly eight rising and eight falling serial-clock transitions must occur per completed transaction.
- `cs_n` stays low from the acceptance edge until completion. No extra select setup or hold intervals beyond the specified timing are required.
- Hold the previous `rx_data` throughout the transaction, including after the eighth sampling transition. Update it only at completion or reset.
- Assert `done` for one internal clock period, then clear it at the next rising edge of `clk`, including if a new transaction starts at that edge.
- The earliest next request acceptance is A+16H+1. No same-edge completion and restart is required.

## Timing Example

Assume reset has completed. At edge A, accept a request with `cfg_half_period=2`; let `T` denote the byte captured from `tx_data`. Assume `start=0` after A and no reset occurs. Values of `T` below always refer to the captured byte, regardless of later input changes.

Every row describes a rising edge of the **internal `clk`**. MISO samples use values **before that edge**. All listed output values are observed **after that edge's register updates**. `Previous` means the last completed received byte, or zero if none has completed since reset.

| Internal edge | Event at edge | `sclk` after edge | `cs_n` after edge | `mosi` after edge | `busy` after edge | `done` after edge | `rx_data` after edge |
|---|---|---|---|---|---|---|---|
| A | Accept and capture request | 0 | 0 | T[7] | 1 | 0 | Previous |
| A+1 | No serial transition | 0 | 0 | T[7] | 1 | 0 | Previous |
| A+2 | First rising transition; sample received bit 7 | 1 | 0 | T[7] | 1 | 0 | Previous |
| A+4 | First falling transition; present next bit | 0 | 0 | T[6] | 1 | 0 | Previous |
| A+6 | Second rising transition; sample received bit 6 | 1 | 0 | T[6] | 1 | 0 | Previous |
| A+8 | Second falling transition; present next bit | 0 | 0 | T[5] | 1 | 0 | Previous |
| ... | Continue the same timing for intervening bits | ... | 0 | ... | 1 | 0 | Previous |
| A+28 | Seventh falling transition; present last bit | 0 | 0 | T[0] | 1 | 0 | Previous |
| A+30 | Eighth rising transition; sample received bit 0 | 1 | 0 | T[0] | 1 | 0 | Previous |
| A+31 | Preserve the final high interval | 1 | 0 | T[0] | 1 | 0 | Previous |
| A+32 | Eighth falling transition; complete transaction | 0 | 1 | 0 | 0 | 1 | Complete received byte |
| A+33 | Idle | 0 | 1 | 0 | 0 | 0 | Complete received byte |

The MOSI bits sampled by the external device at the eight rising transitions must reproduce `T`. For example, `T=8'hA5` produces the bit sequence `1,0,1,0,0,1,0,1`. A MISO sample sequence `0,0,1,1,1,1,0,0` must produce `rx_data=8'h3C` at completion.

## Required Corner Cases

- Raw half-period zero, one, two, and 255. Zero and one must have identical timing.
- Transmit and receive values `00`, `FF`, `80`, `01`, `A5`, and `3C`, to expose bit-order and final-bit mistakes.
- Changes to `tx_data` and `cfg_half_period` during a transaction.
- Extra `start` assertions while busy, including on the completion edge.
- Continuous `start=1` across completion and the next idle acceptance edge.
- Reset during a low or high serial-clock interval, and reset on an otherwise completing edge.
- Holding the previous `rx_data` until the next complete byte is available.

## Task

Implement the module using synthesizable SystemVerilog. Be prepared to explain the half-period counter boundary, the difference between bit-sampling and bit-changing transitions, first-bit preparation, preservation of the last high interval, and use of one internal clock for all state.
