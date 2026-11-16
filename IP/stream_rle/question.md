# SystemVerilog Interview Problem: Byte-Stream Run-Length Encoder

Design a synthesizable run-length encoder (RLE). Replace consecutive identical input bytes with a pair containing the byte and its repetition count. A separate flush interface closes the final run when no different byte follows it.

For example, accepted bytes `11 11 11 22 22 33`, followed by an accepted flush, must produce `(11,3)`, `(22,2)`, and `(33,1)`, in that order. Byte values are hexadecimal; counts are unsigned decimal.

## Interface

```systemverilog
module stream_rle (
    input  logic       clk,
    input  logic       rst_n,

    input  logic [7:0] in_data,
    input  logic       in_valid,
    output logic       in_ready,

    input  logic       flush_valid,
    output logic       flush_ready,

    output logic [7:0] out_data,
    output logic [7:0] out_count,
    output logic       out_valid,
    input  logic       out_ready
);
```

All interfaces use `clk`. Evaluate handshakes at rising edges using values immediately **before** the edge. Registered updates become visible **after** that edge and combinational settling.

## Reset and Protocol

- Use an **active-low synchronous reset**. On a reset edge, discard the active run and any pending output pair, clear `out_valid`, and set `out_data=0` and `out_count=0`. Reset overrides all handshakes on that edge.
- Outside reset, accept a byte when `in_valid && in_ready`, a flush when `flush_valid && flush_ready`, and an output pair when `out_valid && out_ready`.
- Each asserted valid represents a request on every eligible sampling edge. Continuous valid signals are legal; acceptance does not automatically deassert the source's valid signal.
- The byte source must hold `in_valid` and `in_data` stable while `in_valid && !in_ready`. The flush source must hold `flush_valid` high until its request is accepted. Input gaps are legal.
- A flush refers to all bytes accepted before its acceptance edge. If both request interfaces are valid, apply the flush priority defined below; the byte remains unaccepted until an eligible later edge.

## Storage and Run Formation

- Provide capacity for **one active run** and **one pending output pair**, with no additional input or output queue.
- An active run consists of a byte and a count in the range 1 through 255. An empty active-run slot contains no accepted bytes awaiting encoding.
- When a byte is accepted with no active run, start a run containing that byte with count 1. Do not generate an output pair yet.
- When an accepted byte matches the active byte and the active count is less than 255, extend the run by one. Do not generate an output pair.
- When an accepted byte differs from the active byte, generate an output pair for the entire old run and start a new active run containing the newly accepted byte with count 1.
- When the active count is already 255, the next accepted byte must generate the old pair with count 255 and start a new run with count 1, whether or not the byte matches.
- Reaching count 255 by accepting the 255th byte does **not** itself generate a pair. Wait for another accepted byte or an accepted flush.
- Gaps do not close a run. Without an accepted byte or flush, preserve the active run.
- Never generate an output pair with count zero. Preserve all accepted bytes without loss, duplication, or reordering.

## Output Storage and Backpressure

- Generating a pair stores it in the output slot and asserts `out_valid` immediately after that same edge. Do not add another response edge.
- The output slot is available if it is empty, or if its old pair will transfer on the current edge because `out_ready=1`.
- While `out_valid && !out_ready`, hold `out_valid`, `out_data`, and `out_count` stable.
- A pending pair and an active run may coexist. A stalled output must not block bytes that can start or extend the active run without generating another pair.
- If accepting a byte would generate a pair but the output slot is unavailable, do not accept that byte and do not change the active run.
- Allow an old output transfer and generation of its replacement on the same edge. The transfer uses the old pair; after the edge the new pair is valid.
- If an output transfers without replacement, clear `out_valid` after the edge.
- Hold `out_data` and `out_count` on every non-reset edge that does not generate a new pair, including output transfers.
- A newly generated pair cannot transfer on its generation edge: it was not present before that edge.

## Flush and Ready Requirements

- A flush with an active run generates that run's pair and empties the active-run slot. Therefore, it can be accepted only when the output slot is available.
- A flush with no active run is accepted without generating a pair, even if an older output pair is stalled. Do not discard or duplicate that older pair.
- Flushing does not emit a marker. Later input bytes start a fresh run, even if they equal the last flushed byte.
- Give flush requests priority: whenever `flush_valid=1`, force `in_ready=0`, including while the flush is stalled. Never accept a byte and a flush on the same edge. An old output pair may still transfer on either type of acceptance edge.
- Generate `flush_ready` combinationally, independently of `flush_valid`. It must be high exactly when there is no active run or the output slot is available.
- With `flush_valid=0`, generate `in_ready` combinationally and independently of `in_valid`. It must be high exactly when accepting the offered byte can start or extend a run without generating a pair, or when the output slot is available.
- Unlike some streaming interfaces, `in_ready` may depend on `in_data`: a matching byte may be accepted while a different byte would need a blocked output slot.
- With `out_ready=1` and no flush requests, accept one input byte per clock without bubbles, including a stream in which every byte differs from the previous byte.

## Timing Example

Assume reset has completed and both storage slots are empty. Request and `out_ready` columns show values **before each rising edge**. Output transfers use pre-edge values. The last two columns show state and output **after that edge has settled**. Byte values are hexadecimal; counts are decimal.

`Byte XX` means `in_valid=1`, `in_data=XX`, and `flush_valid=0`. `Flush` means `flush_valid=1` and `in_valid=0`. A dash in the request column means both request-valid signals are zero. `Empty` in the last column means `out_valid=0`; otherwise the listed pair has `out_valid=1`. The active-run column is explanatory state, not a required port.

| Edge | Request before edge | `out_ready` before edge | Request accepted? | Output transferred at edge | Active run after edge | Pending output after edge |
|---|---|---|---|---|---|---|
| A | Byte 11 | 0 | Yes | None | (11,1) | Empty |
| A+1 | Byte 11 | 0 | Yes | None | (11,2) | Empty |
| A+2 | Byte 22 | 0 | Yes | None | (22,1) | (11,2) |
| A+3 | Byte 22 | 0 | Yes | None | (22,2) | (11,2) |
| A+4 | Byte 33 | 0 | No | None | (22,2) | (11,2) |
| A+5 | Byte 33 | 1 | Yes | (11,2) | (33,1) | (22,2) |
| A+6 | Flush | 0 | No | None | (33,1) | (22,2) |
| A+7 | Flush | 1 | Yes | (22,2) | Empty | (33,1) |
| A+8 | - | 1 | None requested | (33,1) | Empty | Empty |

At A+3, `in_ready=1` despite output backpressure because the byte only extends the active run. At A+4, `in_ready=0` because a different byte requires another output pair. At A+6, `flush_ready=0`; at A+7, it is 1 and the old output is replaced by the flushed run's pair.

## Required Corner Cases

- One byte followed by a flush; a flush with no previously accepted bytes.
- Consecutive equal bytes and a stream with no adjacent equal bytes.
- Runs of lengths 254, 255, 256, and 510, followed by a flush. For 256 identical bytes, produce counts 255 and 1; for 510, produce 255 and 255.
- A different byte arriving when the active count is exactly 255.
- Starting a run in an empty active-run slot while an older output is stalled.
- An empty-run flush while an older output is stalled: accept the flush and preserve that output.
- Both `in_valid` and `flush_valid` high, including when the flush cannot yet be accepted.
- Simultaneous old-output transfer and new-pair generation, from either a byte request or a flush.
- Reset with both an active run and a stalled output pair.

## Task

Implement the module. Be prepared to explain active-run versus output storage, data-dependent input readiness, count-limit splitting, flush priority, and simultaneous output consumption and replacement.
