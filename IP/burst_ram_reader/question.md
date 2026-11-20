# SystemVerilog Interview Problem: Burst RAM Reader with Backpressure

Design a synthesizable module containing a 16-entry, 8-bit RAM, an independent write port, and a burst-read engine. A read request specifies a starting address and a byte count. Return those bytes in address order through a valid/ready output interface.

## Interface

```systemverilog
module burst_ram_reader (
    input  logic       clk,
    input  logic       rst_n,

    input  logic       wr_en,
    input  logic [3:0] wr_addr,
    input  logic [7:0] wr_data,

    input  logic       req_valid,
    output logic       req_ready,
    input  logic [3:0] req_addr,
    input  logic [4:0] req_len,

    output logic [7:0] out_data,
    output logic       out_valid,
    output logic       out_last,
    input  logic       out_ready
);
```

All inputs are synchronous to `clk`. Evaluate requests and transfers at rising edges using values immediately **before** the edge. Registered outputs become visible **after** that edge's register updates. `req_ready` is combinational.

## Reset and RAM Writes

- Use an **active-low synchronous reset**.
- On a reset edge, cancel any active burst, discard its pending output byte, and set `out_valid=0`, `out_last=0`, and `out_data=0`. Reset overrides requests, output transfers, and writes on that edge.
- Do not reset or initialize RAM contents. Previously written contents survive reset; reading an address before it has been written produces unspecified data.
- On every non-reset edge with `wr_en=1`, write `wr_data` to RAM address `wr_addr`.
- The write port operates independently of burst requests and output readiness. It may write on every clock, including while idle or while an output byte is stalled.

## Request Acceptance

- The request source supplies a legal `req_len` from 1 through 16 whenever `req_valid=1`. Behavior for other lengths is outside this exercise. The length counts bytes, not the final address or length minus one.
- Accept a request when the pre-edge values satisfy `req_valid && req_ready`.
- Support only one active burst, including its pending output byte. Do not queue another request.
- Outside reset, `req_ready` must be high exactly when no burst is active, independently of `req_valid` and `out_ready`.
- On the acceptance edge, capture the starting address and length, fetch the first RAM byte, and present it in `out_data` with `out_valid=1` immediately after that same edge. Set `out_last=1` exactly when the accepted length is one.
- Accepting a request does not transfer its newly fetched byte to the output consumer on that same edge: the byte was not valid before the edge.
- Later changes to `req_addr` and `req_len` must not affect the accepted burst.
- The request source must hold `req_valid`, `req_addr`, and `req_len` stable while `req_valid && !req_ready`.
- Continuous `req_valid=1` is legal. Each eligible acceptance edge starts a new burst; accepting a request does not automatically lower the source's valid signal.

## Burst Sequence and Output Transfers

- An output byte transfers when the pre-edge values satisfy `out_valid && out_ready`.
- A length-`N` request starting at address `A` must produce exactly `N` bytes, using addresses `A`, `A+1`, through `A+N-1`, with all addresses taken modulo 16.
- For example, starting at address 14 with length 3 visits addresses 14, 15, and 0.
- Use capacity for one buffered output byte in addition to RAM and burst control state. Do not prefetch additional bytes or copy the entire burst into another buffer.
- The first byte is fetched on the request-acceptance edge. Each later byte is fetched on the edge that transfers its predecessor, provided the burst has another byte remaining.
- After a non-final byte transfers, replace the output with the next fetched byte immediately after that same edge. Keep `out_valid=1`; set `out_last` according to whether that replacement is the final byte.
- With `out_ready=1`, produce one output transfer per clock after the initial request-acceptance edge, with no gaps inside a burst.
- While `out_valid && !out_ready`, hold `out_valid`, `out_data`, and `out_last` stable. Do not advance the burst address, consume its length, or fetch its next byte.
- `out_last` belongs to the pending byte and must remain high while a final byte is stalled. Reaching the last address or fetching the final byte does not by itself complete the burst.
- Complete the burst only when its final byte transfers. After that edge, clear `out_valid` and `out_last`; hold `out_data` unchanged.
- A burst is still active immediately before its final transfer edge, so `req_ready=0` before that edge. Do not accept another request on that edge. The earliest next acceptance is the following rising edge.
- On every non-reset edge that fetches no byte, hold `out_data` unchanged. While idle, keep `out_valid=0` and `out_last=0`.

## Concurrent RAM Reads and Writes

- A fetch must observe the RAM byte as it existed **before its fetch edge**. A write to the same address on that edge updates memory for future fetches but must not change the byte being captured on that edge.
- This read-before-write rule applies both to the first byte of a new burst and to replacement bytes fetched after output transfers.
- A byte already in the output register must not change when its RAM address is written, including during an output stall.
- A future byte is not snapshotted when the burst starts. Writes that finish before that byte's fetch edge must be visible to its fetch.
- No extra read-latency cycle is allowed beyond the specified fetch edges. Use any synthesizable RAM representation that satisfies these behaviors; no particular physical memory primitive is required.

## Timing Example

Assume reset has completed and earlier writes have established these contents: RAM address `E` contains `E0`, address `F` contains `F0`, address `0` contains `A0`, and address `1` contains `B0`.

Addresses and byte data below are hexadecimal; lengths are decimal. `Read A/N` means `req_valid=1`, `req_addr=A`, and `req_len=N`. `Write A:D` means `wr_en=1`, `wr_addr=A`, and `wr_data=D`. A dash means the corresponding request or write enable is zero.

Request, write, `out_ready`, and `req_ready` columns show values **before each named rising edge**. Output transfers use pre-edge values. The final three columns show outputs **after that edge's updates and settling**.

| Edge | Read request before edge | Write before edge | `out_ready` before edge | `req_ready` before edge | Byte transferred at edge | `out_valid` after edge | `out_data` after edge | `out_last` after edge |
|---|---|---|---|---|---|---|---|---|
| A | Read E/3 | - | 0 | 1 | None | 1 | E0 | 0 |
| A+1 | - | Write E:E1 | 0 | 0 | None | 1 | E0 | 0 |
| A+2 | - | Write F:F1 | 0 | 0 | None | 1 | E0 | 0 |
| A+3 | - | Write F:F2 | 1 | 0 | E0 | 1 | F1 | 0 |
| A+4 | - | Write 0:A1 | 1 | 0 | F1 | 1 | A0 | 1 |
| A+5 | Read 1/1 | - | 1 | 0 | A0 | 0 | A0 | 0 |
| A+6 | Read 1/1 | Write 1:B1 | 1 | 1 | None | 1 | B0 | 1 |
| A+7 | - | - | 1 | 0 | B0 | 0 | B0 | 0 |

At A+1, writing the address of the stalled output does not replace its buffered `E0`. At A+3, the fetch sees `F1` from the earlier write, while the simultaneous `F2` write affects future reads. At A+4, address wraparound fetches address zero and sees `A0`, not the concurrently written `A1`. The request at A+5 remains unaccepted and is held until A+6. The first byte of that new request cannot transfer until A+7.

## Required Corner Cases

- Length one and length sixteen.
- Address wraparound, including a length-sixteen burst starting at a nonzero address.
- Stalls on the first, middle, and final output byte.
- Changes to request address and length after an accepted request.
- Writes to the currently buffered address during a stall.
- Writes to a future burst address before its fetch, and simultaneous read/write of the fetched address.
- A new request waiting during the previous burst's final transfer.
- Continuous `req_valid=1`, with a new burst accepted on each eligible idle edge.
- Reset during a burst, preserving RAM contents while discarding the unfinished output sequence.

## Task

Implement the module using synthesizable SystemVerilog. Be prepared to explain fetch versus transfer timing, remaining-byte counting, address wraparound, stalled-final-byte handling, and the effect of concurrent writes on buffered versus future bytes.
