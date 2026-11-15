# SystemVerilog Interview Problem: Four-Input Stable Signed Sorter

Design a synthesizable module that sorts four signed 8-bit values in ascending order and reports the original input index of each sorted value. Equal values must retain their original lane order.

## Interface

```systemverilog
module signed_sort4 (
    input  logic            clk,
    input  logic            rst_n,
    input  logic            in_valid,
    input  logic [3:0][7:0] in_data,

    output logic            out_valid,
    output logic [3:0][7:0] out_data,
    output logic [3:0][1:0] out_index
);
```

All inputs are synchronous to `clk`. Requests use the values immediately before each rising edge. Registered outputs become visible after that edge's register updates. There are no ready signals and no output backpressure.

## Lane and Number Conventions

- `in_data[i]` is input lane `i`, for indices 0 through 3.
- Interpret each lane independently as an **8-bit signed two's-complement number**, in the range -128 through +127. The packed bus declaration does not change this required interpretation.
- `out_data[k]` is the value at sorted position `k`, and `out_index[k]` is its original input lane index. Position 0 contains the smallest value.
- Preserve each selected value's original 8-bit representation. For example, `8'hFF` means -1, `8'h80` means -128, and `8'h7F` means +127.
- Every tuple in this statement is written in **lane order `(0,1,2,3)`**, not packed concatenation order. For example, the tuple `(10,20,30,40)` means `in_data[0]=10` and `in_data[3]=40`; the equivalent packed concatenation is `{8'd40, 8'd30, 8'd20, 8'd10}`.

## Reset and Acceptance

- Use an **active-low synchronous reset**.
- At a rising edge with `rst_n=0`, clear `out_valid`, all four output-data lanes, and all four output-index lanes to zero. Reset overrides any input request at that edge.
- On every non-reset edge with `in_valid=1`, accept the complete four-lane group and produce its sorted result immediately after that same edge. Do not add another response edge.
- Set `out_valid=1` for that result. Consecutive valid input groups must produce consecutive valid output groups, with one group accepted per clock.
- Continuous `in_valid=1` is legal; each non-reset rising edge accepts another group.
- On a non-reset edge with `in_valid=0`, clear `out_valid` and hold all `out_data` and `out_index` lanes unchanged. Ignore `in_data` on that edge.
- Outputs must be registered. Changing inputs between rising edges must not change the outputs.

## Sorting and Stability Requirements

For every valid result:

- Values must be in ascending **signed** order: `out_data[0] <= out_data[1] <= out_data[2] <= out_data[3]`, with each lane interpreted as signed.
- The four output indices must be a permutation of 0, 1, 2, and 3. No input lane may be lost or duplicated.
- Each output value must correspond to its reported index: `out_data[k]` must equal the accepted input group's `in_data[out_index[k]]`.
- Equal values must appear in increasing original-index order. For example, input `(7,-1,7,-1)` must produce values `(-1,-1,7,7)` with indices `(1,3,0,2)`.
- If all four values are equal, output indices must be `(0,1,2,3)`.
- Each input group is independent. Do not combine values from different sampling edges.

## Timing Example

Assume reset has completed. The first two columns after the edge label show inputs **before the named rising edge**. All output columns show registered values **after that edge has settled**. Data values are signed decimal, indices are unsigned decimal, and all tuples use lane order `(0,1,2,3)`.

| Edge | `in_valid` before edge | `in_data` before edge | `out_valid` after edge | `out_data` after edge | `out_index` after edge |
|---|---|---|---|---|---|
| A | 1 | (-1,7,-128,7) | 1 | (-128,-1,7,7) | (2,0,1,3) |
| A+1 | 1 | (5,5,5,5) | 1 | (5,5,5,5) | (0,1,2,3) |
| A+2 | 0 | Don't care | 0 | (5,5,5,5) | (0,1,2,3) |
| A+3 | 1 | (127,-128,0,-1) | 1 | (-128,-1,0,127) | (1,3,2,0) |
| A+4 | 1 | (0,-1,0,-1) | 1 | (-1,-1,0,0) | (1,3,0,2) |

At A, the two values equal to 7 must retain the order of original lanes 1 and 3. At A+2, output data and indices still hold the previous result, but `out_valid=0` means no new result is present.

If a downstream register samples these outputs, it uses their pre-edge values. For example, at A+1 it can accept the result produced after A, while this module updates its outputs with the next result after A+1.

## Required Corner Cases

- Already sorted and reverse-sorted inputs.
- All negative values, all nonnegative values, and mixed signs.
- The signed endpoints -128 and +127 in the same group.
- Two equal values, three equal values, and four equal values.
- Duplicate minimum and maximum values, including duplicates in nonadjacent input lanes.
- Consecutive valid groups and gaps between groups.
- Reset while `in_valid=1`, followed by a new valid group on the next non-reset edge.

## Implementation Requirements

- Use synthesizable SystemVerilog. Do not use array sorting methods, delays, or simulation-only sorting utilities.
- Complete the sorting through combinational logic feeding registered outputs; do not spend multiple clocks sorting a group.
- Any synthesizable comparison structure meeting the behavior and timing requirements is acceptable. No particular sorting algorithm, number of comparisons, or internal array layout is prescribed.

## Task

Implement the module. Be prepared to explain signed comparisons of individual lanes, preservation of value/index correspondence, stable ordering for equal values, and the distinction between combinational comparison depth and clock-cycle latency.
