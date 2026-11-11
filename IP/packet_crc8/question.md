# Verilog Interview Problem: Packet CRC-8 Calculator

Design a synthesizable module that accepts packets of bytes and produces one 8-bit CRC result per packet. Both interfaces use a valid/ready handshake.

## Interface

```systemverilog
module packet_crc8 (
    input  logic       clk,
    input  logic       rst_n,

    input  logic [7:0] in_data,
    input  logic       in_valid,
    input  logic       in_last,
    output logic       in_ready,

    output logic [7:0] out_crc,
    output logic       out_valid,
    input  logic       out_ready
);
```

All inputs are synchronous to `clk`. No clock-domain crossing logic is required.

## Packet Protocol

- An input byte is accepted at a rising edge when the pre-edge values satisfy `in_valid && in_ready`.
- `in_last=1` marks the final byte of a packet and has meaning only when that byte is accepted.
- Every packet has at least one byte. A one-byte packet has `in_last=1` on its only byte. There is no maximum packet length.
- The first accepted byte after reset or after an accepted final byte starts a new packet. There is no separate start signal.
- Input gaps are legal. The upstream keeps `in_valid`, `in_data`, and `in_last` stable while `in_valid && !in_ready`.
- Continuous `in_valid=1` is legal. Every eligible rising edge accepts another byte; accepting a byte does not automatically lower the upstream's valid signal.
- A result is transferred at a rising edge when the pre-edge values satisfy `out_valid && out_ready`.

## CRC Definition

Use the polynomial `x^8 + x^2 + x + 1`, represented by `8'h07`, with an initial CRC of `8'h00` for each packet. Process bytes in arrival order and bits within each byte from bit 7 down to bit 0. Do not reflect input bits or result bits, and do not complement or apply a final XOR to the result. Do not append extra zero bits after the final byte.

The following bit-level rule fully defines the required result. Let `C` be the current 8-bit CRC and `b` the next input bit:

1. Determine the feedback bit as `C[7] XOR b`, using the old value of `C`.
2. Shift `C` left by one bit, discard the old bit 7, and insert zero at bit 0.
3. If the feedback bit is 1, XOR the shifted value with `8'h07`; otherwise keep the shifted value.

Apply this rule to all eight bits of every accepted byte. The packet result is the CRC after processing its final byte, including all eight bits of that byte.

## Timing and Storage Requirements

- Use an **active-low synchronous reset**. At a rising edge with `rst_n=0`, discard any partial packet and pending result, clear `out_valid`, and set `out_crc=0`. Reset overrides all transfers on that edge.
- Outside reset, accept one byte per clock while accumulating a packet. Compute the complete eight-bit update for each accepted byte by the end of that same edge's register updates; do not spend eight clocks processing a byte.
- An edge without an input acceptance must not advance or restart the packet CRC.
- Immediately after the edge that accepts a final byte, set `out_valid=1` and update `out_crc` with that packet's result. Do not add another response cycle.
- The new result cannot be transferred on its final-byte acceptance edge because it was not valid before that edge.
- Provide capacity for one pending result. Do not buffer input bytes or accumulate another packet while a pending result is stalled.
- Generate `in_ready` combinationally and independently of `in_valid`, `in_last`, and `in_data`. It must be high when no result is pending, or when the pending result will be accepted on the upcoming edge because `out_ready=1`. Otherwise it must be low.
- While `out_valid && !out_ready`, keep `out_valid` and `out_crc` stable and accept no input bytes.
- Allow a pending result transfer and a new input byte acceptance on the **same edge**. That input byte is the first byte of the next packet and must use an initial CRC of zero.
- If that replacement byte also has `in_last=1`, replace the old result with the new one after the edge and keep `out_valid=1`. The output transfer on that edge still uses the old result.
- If a pending result transfers without a new final byte being accepted, clear `out_valid` after the edge.
- Hold `out_crc` unchanged on every non-reset edge that does not accept a final byte, including idle cycles and result transfers. Internal partial-packet progress must not appear on `out_crc`.
- Support back-to-back packets, including consecutive one-byte packets. With `out_ready=1`, the input must accept one byte per clock without bubbles.

## Timing Example

Assume reset has completed: the next accepted byte starts a new packet, `out_valid=0`, and `out_crc=00`.

All input columns and `in_ready` show values **immediately before the named rising edge**. Transfers use those pre-edge values. The final two columns show outputs **after register updates and combinational settling**. All byte and CRC values are hexadecimal.

| Edge | `in_valid` | `in_data` | `in_last` | `out_ready` | `in_ready` before edge | Transfers at edge | `out_valid` after edge | `out_crc` after edge |
|---|---|---|---|---|---|---|---|---|
| A | 1 | 12 | 0 | 0 | 1 | Accept byte 12 | 0 | 00 |
| A+1 | 0 | -- | -- | 0 | 1 | None; preserve partial CRC | 0 | 00 |
| A+2 | 1 | 34 | 1 | 0 | 1 | Accept final byte 34 | 1 | F1 |
| A+3 | 1 | AB | 1 | 0 | 0 | None; result is stalled | 1 | F1 |
| A+4 | 1 | AB | 1 | 1 | 1 | Transfer F1; accept one-byte packet AB | 1 | 58 |
| A+5 | 0 | -- | -- | 1 | 1 | Transfer 58 | 0 | 58 |
| A+6 | 1 | 00 | 1 | 1 | 1 | Accept one-byte packet 00 | 1 | 00 |
| A+7 | 0 | -- | -- | 1 | 1 | Transfer 00 | 0 | 00 |

At A+2, the result must include byte 34, rather than reporting the CRC of byte 12 alone. At A+4, the new packet must start from zero instead of continuing the previous packet's CRC. A packet with CRC zero still produces a valid result.

## Additional Expected Results

```text
Packet bytes                         CRC
00                                   00
01                                   07
12                                   7E
12 34                                F1
AB                                   58
31 32 33 34 35 36 37 38 39           F4
```

## Task

Implement the module. Be prepared to explain bit-processing order, inclusion of the final byte, preservation across input gaps, and simultaneous old-result consumption and new-packet acceptance.
