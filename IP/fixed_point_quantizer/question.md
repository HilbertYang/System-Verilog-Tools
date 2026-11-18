# SystemVerilog Interview Problem: Signed Fixed-Point Quantizer

Design a synthesizable module that converts a signed fixed-point input into a signed 8-bit integer. Round to the nearest integer, resolving exact halfway cases toward the even integer, then saturate the rounded result to the output range.

## Interface

```systemverilog
module fixed_point_quantizer (
    input  logic               clk,
    input  logic               rst_n,
    input  logic               in_valid,
    input  logic signed [16:0] in_data,

    output logic               out_valid,
    output logic signed [7:0]  out_data,
    output logic               out_sat
);
```

All inputs are synchronous to `clk`. Input values are sampled immediately **before** each rising edge. Registered outputs become visible **after** that edge's register updates. No ready signals or output backpressure are required.

## Input Representation

- Interpret `in_data` as a signed 17-bit two's-complement integer `S`.
- The represented numerical value is `x = S / 256`. Thus the input has eight fractional bits and a resolution of `1/256`.
- The raw integer range is -65536 through +65535; the represented value range is -256 through +255.99609375.
- Examples: raw `S=384` represents +1.5, raw `S=-384` represents -1.5, and raw `S=-256` represents -1.0.
- This is a fixed-point bit-vector interface, not a floating-point encoding. Fractional values in this statement describe the meaning of those bits; do not use `real` or `shortreal` in the implementation.

## Rounding Rule

First compute a mathematical integer `R` by rounding `x` to the nearest integer:

- If one integer is strictly closer to `x` than any other, choose that integer.
- If `x` is exactly halfway between two adjacent integers, choose the **even integer**.
- Apply this rule to both positive and negative inputs. It is not rounding every halfway case upward or away from zero.
- Examples:

| Represented input `x` | Rounded integer `R` |
|---|---|
| +1.25 | 1 |
| +1.75 | 2 |
| +1.5 | 2 |
| +2.5 | 2 |
| +3.5 | 4 |
| -1.25 | -1 |
| -1.75 | -2 |
| -1.5 | -2 |
| -2.5 | -2 |
| +0.5 | 0 |
| -0.5 | 0 |

## Saturation Rule

After rounding, convert `R` to the signed 8-bit output range, -128 through +127:

- If `R > 127`, output `out_data=127` and `out_sat=1`.
- If `R < -128`, output `out_data=-128` and `out_sat=1`.
- Otherwise, output `out_data=R` and `out_sat=0`.
- A rounded result exactly equal to -128 or +127 is in range and must not assert `out_sat`.
- Saturation is determined from the **rounded integer**, not directly from the original fixed-point value. For example, -128.5 rounds to -128 and does not saturate, while +127.5 rounds to +128 and does saturate.
- Preserve enough intermediate precision to determine rounding and saturation correctly before storing the final 8-bit output. Do not allow intermediate wraparound to change the decision.
- `out_sat` indicates clipping, not merely the removal of a nonzero fractional part. For example, +1.5 produces integer 2 with `out_sat=0`.

## Reset, Acceptance, and Output Timing

- Use an **active-low synchronous reset**.
- At a rising edge with `rst_n=0`, clear `out_valid`, `out_data`, and `out_sat`. Reset overrides input acceptance on that edge.
- On every non-reset edge with `in_valid=1`, accept one sample and set `out_valid=1`. Produce its rounded, saturated result and clipping flag immediately after that same edge; do not add another response edge.
- Support one independent sample per clock, including continuous `in_valid=1`. Each eligible rising edge accepts another sample.
- On a non-reset edge with `in_valid=0`, clear `out_valid` and hold both `out_data` and `out_sat` unchanged. Ignore `in_data` on that edge.
- `out_sat` is a result field qualified by `out_valid`. It is not a pulse that must clear during an input gap, and it is not a sticky history flag: each new accepted sample supplies its own flag value.
- All outputs must be registered. Input changes between rising edges must not change them.

## Timing Example

Assume reset has completed. The input columns show values **before the named rising edge**. Output columns show values **after that edge's register updates and settling**. Raw inputs and integer outputs are signed decimal. The `x` column only explains the represented value; it is not an additional port.

| Edge | `in_valid` before edge | Raw `in_data` before edge | Represented `x` | `out_valid` after edge | `out_data` after edge | `out_sat` after edge |
|---|---|---|---|---|---|---|
| A | 1 | 384 | +1.5 | 1 | 2 | 0 |
| A+1 | 1 | 640 | +2.5 | 1 | 2 | 0 |
| A+2 | 1 | -384 | -1.5 | 1 | -2 | 0 |
| A+3 | 1 | -640 | -2.5 | 1 | -2 | 0 |
| A+4 | 1 | 32576 | +127.25 | 1 | 127 | 0 |
| A+5 | 1 | 32640 | +127.5 | 1 | 127 | 1 |
| A+6 | 1 | -32896 | -128.5 | 1 | -128 | 0 |
| A+7 | 1 | -32960 | -128.75 | 1 | -128 | 1 |
| A+8 | 1 | 65535 | +255.99609375 | 1 | 127 | 1 |
| A+9 | 1 | -65536 | -256 | 1 | -128 | 1 |
| A+10 | 0 | Don't care | -- | 0 | -128 | 1 |
| A+11 | 1 | 128 | +0.5 | 1 | 0 | 0 |
| A+12 | 1 | -128 | -0.5 | 1 | 0 | 0 |

At A+5, the rounded integer is 128, so clipping is required even though the output is the same as at A+4. At A+6, the even halfway choice is -128, which is representable without clipping. At A+10, the previous result fields are held, but no new result is valid.

## Required Corner Cases

- Exact integers, including zero and both output limits.
- Positive and negative values below, at, and above a halfway point. Include inputs one raw least-significant bit below and above that point.
- Halfway cases whose neighboring integers include zero, positive even and odd integers, and negative even and odd integers.
- Values near +127 and -128 where rounding changes whether saturation is required.
- The minimum and maximum raw 17-bit inputs.
- Alternating positive and negative samples on consecutive clocks.
- A clipped sample followed by an input gap and then an unclipped sample.
- Reset concurrent with `in_valid=1`.

## Task

Implement the module using synthesizable fixed-width integer/vector logic, without floating-point types or simulation-only mathematical routines. Be prepared to explain negative-value rounding, exact halfway detection, even-integer selection, intermediate width, and why rounding must precede saturation.
