# SystemVerilog Interview Problem: Token-Bucket Stream Gate

Design a synthesizable module that limits admission of input requests using a token bucket. Each request carries one data byte and a token cost. External refill events add tokens, and accepted requests spend them. A single output slot holds admitted data until the downstream accepts it.

The bucket capacity is **15 tokens**. Tokens are accounting units, not data bytes. For example, a request costing 3 tokens consumes 3 tokens but produces exactly one output byte.

## Interface

```systemverilog
module token_bucket_gate (
    input  logic       clk,
    input  logic       rst_n,

    input  logic       refill_valid,
    input  logic [3:0] refill_amount,
    output logic [3:0] token_count,

    input  logic       in_valid,
    output logic       in_ready,
    input  logic [7:0] in_data,
    input  logic [3:0] in_cost,

    output logic       out_valid,
    input  logic       out_ready,
    output logic [7:0] out_data
);
```

All inputs are synchronous to `clk`. No clock-domain crossing logic is required.

## Reset and Transfers

- Use an **active-low synchronous reset**. At a rising edge with `rst_n=0`, set `token_count=0`, `out_valid=0`, and `out_data=0`. Reset overrides refills and both transfers on that edge.
- Outside reset, an input request is accepted at a rising edge when the **pre-edge** values satisfy `in_valid && in_ready`.
- An output byte is transferred at a rising edge when the **pre-edge** values satisfy `out_valid && out_ready`.
- The upstream must hold `in_valid`, `in_data`, and `in_cost` stable while `in_valid && !in_ready`. Continuous `in_valid=1` is legal; each eligible edge accepts another request.
- Readiness requirements below apply outside reset. No particular value of `in_ready` is required while `rst_n=0`.

## Token Accounting

- `token_count` reports the currently stored number of tokens, from 0 through 15. It changes only after a rising edge; it must not directly include an unsampled refill.
- At every non-reset rising edge with `refill_valid=1`, add `refill_amount` tokens, limited to the bucket capacity of 15. Refill has no ready signal and must be processed even when the output is stalled or no input is present.
- Ignore `refill_amount` when `refill_valid=0`. A valid refill of zero has no effect.
- An input cost of zero means a cost of **1 token**. Other costs mean their unsigned values, from 1 through 15.
- For admission at a given edge, apply that edge's refill and capacity limit **before** considering the input cost. Tokens supplied by the current refill may be spent on a request accepted at that same edge.
- Excess refill tokens are discarded before any spending. For example, with 14 stored tokens, a refill of 5, and an accepted request costing 4, the count after the edge is **11**, not 15.
- Spend the effective input cost exactly once, on input acceptance. An unaccepted request must not spend tokens.
- Output transfers do not spend or refund tokens. A request has already paid when it enters the output slot.
- If no request is accepted, store the refill-adjusted count. If neither a refill nor an input acceptance occurs, hold the count unchanged.
- The count must never wrap around or become negative.

## Readiness and Output Storage

- Provide capacity for exactly one pending output byte. Do not queue additional requests or data internally.
- Generate `in_ready` combinationally, independently of `in_valid` and `in_data`. It may depend on `in_cost`, the refill inputs, the stored token count, and output-slot availability.
- Outside reset, `in_ready` must be high **if and only if both** of the following are true:
  1. The output slot is empty, or its current byte will transfer on the upcoming edge because `out_ready=1`.
  2. There are enough tokens to pay the effective input cost after applying the current refill and capacity limit.
- Immediately after an edge that accepts an input, place its `in_data` in the output slot and set `out_valid=1`. Do not add another response cycle.
- There is no combinational data bypass from input to output. A byte accepted at edge A is first available after A and cannot transfer downstream before edge A+1.
- Allow an old output transfer and a new input acceptance on the same edge. The downstream receives the old byte at that edge; the new byte replaces it after the edge, keeping `out_valid=1`.
- If an output transfers without a replacement input acceptance, clear `out_valid` after the edge.
- While `out_valid && !out_ready`, hold `out_valid` and `out_data` stable and accept no input. Refills must still update the token count.
- Hold `out_data` unchanged on every non-reset edge without an input acceptance, including output transfers and idle cycles. Its value is meaningful to the downstream only when `out_valid=1`.
- Support consecutive input acceptances without bubbles whenever tokens and downstream capacity permit.

## Timing Example

Assume reset has completed, leaving zero tokens and an empty output slot. All token counts and costs below are decimal; data bytes are hexadecimal.

All request inputs, `out_ready`, and the listed `in_ready` are values **before the named rising edge**. Transfers use those pre-edge values. The last three columns show state **after that edge's register updates and combinational settling**. `--` means the associated valid signal is zero.

| Edge | Refill before edge | Input before edge: data / cost | `out_ready` | `in_ready` before edge | Transfers at edge | `token_count` after edge | `out_valid` after edge | `out_data` after edge |
|---|---|---|---|---|---|---|---|---|
| A | 3 | A1 / 2 | 0 | 1 | Accept A1 | 1 | 1 | A1 |
| A+1 | 7 | B2 / 3 | 0 | 0 | None; output stalled | 8 | 1 | A1 |
| A+2 | 10 | B2 / 3 | 1 | 1 | Transfer A1; accept B2 | 12 | 1 | B2 |
| A+3 | -- | C3 / 15 | 1 | 0 | Transfer B2; insufficient tokens for C3 | 12 | 0 | B2 |
| A+4 | 3 | C3 / 15 | 0 | 1 | Accept C3 using current refill | 0 | 1 | C3 |
| A+5 | 1 | D4 / 0 | 0 | 0 | None; output stalled | 1 | 1 | C3 |
| A+6 | -- | D4 / 0 | 1 | 1 | Transfer C3; accept D4 at effective cost 1 | 0 | 1 | D4 |
| A+7 | -- | -- | 1 | 0* | Transfer D4 | 0 | 0 | D4 |

Every shown input request has `in_valid=1`; the final row has `in_valid=0` and, for definiteness, `in_cost=1`, so the marked readiness value is 0. Every numbered refill has `refill_valid=1`.

At A+2, the stored count of 8 plus a refill of 10 is first limited to 15. Accepting B2 then spends 3, leaving 12. At A+5, the refill is retained even though the output stall prevents input acceptance.

## Task

Implement the module. Be prepared to explain same-edge refill use, capacity limiting before spending, zero-cost normalization, token preservation during output stalls, and simultaneous output consumption and input replacement.
