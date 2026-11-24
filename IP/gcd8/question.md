# SystemVerilog Interview Problem: Iterative 8-Bit GCD Calculator

Design a synthesizable module that calculates the greatest common divisor (GCD) of two unsigned 8-bit integers using the subtraction-based Euclidean algorithm.

For two positive integers, their GCD is the largest positive integer that divides both without a remainder. For example, `GCD(48, 18) = 6` and `GCD(35, 64) = 1`. For this exercise, define `GCD(0, b) = b`, `GCD(a, 0) = a`, and `GCD(0, 0) = 0`.

## Interface

```systemverilog
module gcd8 (
    input  logic       clk,
    input  logic       rst_n,
    input  logic       start,
    input  logic [7:0] a,
    input  logic [7:0] b,

    output logic       busy,
    output logic       done,
    output logic [7:0] result
);
```

All inputs are synchronous to `clk`. Operands and results are unsigned.

## Reset and Request Acceptance

- Use an **active-low synchronous reset**. At a rising edge with `rst_n=0`, set `busy=0`, `done=0`, and `result=0`, and cancel any operation in progress. Reset has priority over every other operation.
- Outside reset, accept a request on a rising edge when the **pre-edge** values satisfy `start && !busy`.
- Capture both operands on acceptance and set `busy=1` after that edge. Later changes to `a` and `b` must not affect the accepted operation.
- The acceptance edge initializes the operation; it is **not** a processing edge. Do not publish a result at the acceptance edge, even for zero or equal operands.
- Ignore `start` while `busy=1`; do not queue requests.

## Required Processing Behavior

Use two unsigned working operands initialized from the accepted inputs. Apply the following rules at each rising edge whose **pre-edge** `busy` is 1, using the working values that existed before that edge:

- If either working operand is zero, finish with the other operand as the result. If both are zero, finish with zero.
- Otherwise, if both working operands are equal, finish with that common value.
- Otherwise, subtract the smaller working operand from the larger one and replace only the larger operand with the difference. Keep `busy=1` and continue on the next edge.
- A subtraction that makes the operands equal does **not** finish the operation on that same edge. Detect the terminal condition and publish the result at the next processing edge.
- Perform at most one working-operand subtraction per processing edge. Do not unroll multiple Euclidean steps into one clock cycle.
- Do not use division, modulus, multiplication, a GCD system function, or a precomputed answer table. Comparisons, subtraction, and ordinary control logic are allowed.
- Do not use early exits or special cases that change the specified processing-edge sequence.

The latency is intentionally variable. In particular, zero operands or equal operands finish on the first processing edge, while other inputs may require many subtraction edges.

## Completion and Output Behavior

- On a finishing edge, update `result`, set `done=1`, and clear `busy` immediately after that edge's register updates. Do not add another result cycle.
- Clear `done` on every non-reset edge that does not finish an operation. A completion indication therefore lasts exactly one clock cycle.
- Hold `result` unchanged on all non-reset edges that do not finish an operation, including request acceptance, intermediate processing, and idle cycles.
- Ignore a request presented on the finishing edge because `busy` was still 1 before that edge.
- The earliest next request acceptance is the edge immediately following completion. That new acceptance must clear `done`, assert `busy`, and preserve the previous `result`.
- Continuous `start=1` is legal: it causes another acceptance at the next eligible idle edge. Capture the input values present before that new acceptance edge.
- No output ready signal or result backpressure is required. `done` identifies a newly completed result, and `result` remains available until a later completion or reset.

## Timing Example

Assume reset has completed. Request inputs in the second column are values **before the named rising edge**. The final three columns show outputs **after that edge's register updates**. The first request is `(48, 18)`; changes to external operands while busy do not affect it.

| Edge | Request before edge | Action at edge | `busy` after edge | `done` after edge | `result` after edge |
|---|---|---|---|---|---|
| A | `start=1, a=48, b=18` | Accept; initialize working operands | 1 | 0 | Previous result |
| A+1 | `start=0` | First subtraction | 1 | 0 | Previous result |
| A+2 | `start=0` | Second subtraction | 1 | 0 | Previous result |
| A+3 | `start=0` | Third subtraction | 1 | 0 | Previous result |
| A+4 | `start=0` | Fourth subtraction; working operands become equal | 1 | 0 | Previous result |
| A+5 | `start=1, a=0, b=27` | Finish first request; ignore offered request | 0 | 1 | 6 |
| A+6 | `start=1, a=0, b=27` | Accept second request | 1 | 0 | 6 |
| A+7 | `start=0` | Finish second request | 0 | 1 | 27 |
| A+8 | `start=0` | Idle | 0 | 0 | 27 |

## Boundary Cases

For each independent request below, let A be its acceptance edge. The finishing edge includes the terminal-condition check and is the edge after which `done` must be high.

| Accepted operands | Expected result | Subtraction edges | Finishing edge |
|---|---|---|---|
| 0, 0 | 0 | None | A+1 |
| 0, 27 | 27 | None | A+1 |
| 42, 0 | 42 | None | A+1 |
| 255, 255 | 255 | None | A+1 |
| 12, 8 | 4 | A+1 through A+2 | A+3 |
| 255, 1 | 1 | A+1 through A+254 | A+255 |
| 1, 255 | 1 | A+1 through A+254 | A+255 |

## Task

Implement the module. Be prepared to explain operand capture, unsigned subtraction, termination, result retention, reset during computation, and why a request on the finishing edge is ignored while one on the following edge can be accepted.
