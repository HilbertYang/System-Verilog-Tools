# Unsigned Restoring Divider

This directory contains an unsigned bit-serial restoring divider for learning about divider datapaths.

## Hardware Structure

The divider consists mainly of the following components:

- `quotient_work`: initially holds the dividend and becomes the quotient after the iterations.
- `remainder_work`: holds the partial remainder produced by each iteration.
- `divisor_reg`: holds the divisor throughout the operation.
- Comparator/subtractor: determines whether the divisor can be subtracted from the partial remainder.
- `iteration`: tracks how many bits have been processed.

Each cycle, data follows approximately this path:

```text
 Most significant bit of quotient_work
                 |
                 v
 Shift remainder_work left and append that bit
                 |
                 v
 Compare with divisor_reg and subtract if needed
                 |
                 v
 Write the comparison result to the least significant bit of quotient_work
```

A `DATA_WIDTH`-bit division processes `DATA_WIDTH` quotient bits, so division by a
nonzero divisor takes `DATA_WIDTH` iteration cycles.

## Example: 13 / 3

Using 4-bit registers:

```text
Initial      remainder=0000  quotient=1101
Iteration 1  remainder=0001  quotient=1010
Iteration 2  remainder=0000  quotient=0101
Iteration 3  remainder=0000  quotient=1010
Iteration 4  remainder=0001  quotient=0100
```

Final result:

```text
quotient  = 0100 = 4
remainder = 0001 = 1
```

That is, `13 = 4 * 3 + 1`.

## Interface Timing

```text
start && ready  Accept dividend and divisor
busy            Remains 1 during iterations for division by a nonzero divisor
done            Asserts for one clock cycle when the result is complete
ready           Is 1 when busy=0
```

When `divisor=0`, the module skips the iteration state and directly returns:

```text
quotient    = 0
remainder   = dividend
div_by_zero = 1
```

## Simulation

Run from the repository root:

```bash
iverilog -g2012 -o /tmp/tb_unsigned_divider.vvp \
  IP/unsigned_divider/unsigned_restoring_divider.sv \
  IP/unsigned_divider/tb_unsigned_restoring_divider.sv
vvp /tmp/tb_unsigned_divider.vvp
```
