# SystemVerilog Interview Problem: Packet FIFO with Commit and Abort

Design a synthesizable FIFO that stores packets of bytes. A packet must remain invisible to the output until its final byte has been accepted. An abort request discards the current unfinished packet while preserving all previously completed packets.

The FIFO has a total capacity of **eight bytes**, shared by completed packets and the current unfinished packet. Multiple completed packets may be queued.

## Interface

```systemverilog
module packet_commit_fifo (
    input  logic       clk,
    input  logic       rst_n,

    input  logic       in_valid,
    output logic       in_ready,
    input  logic [7:0] in_data,
    input  logic       in_last,
    input  logic       abort,

    output logic       out_valid,
    input  logic       out_ready,
    output logic [7:0] out_data,
    output logic       out_last
);
```

All inputs are synchronous to `clk`. No clock-domain crossing logic is required.

## Reset and Packet Protocol

- Use an **active-low synchronous reset**. At a rising edge with `rst_n=0`, discard every stored byte and all packet progress. After the edge, the FIFO is empty, `out_valid=0`, `out_data=0`, and `out_last=0`. Reset overrides abort and all transfers on that edge.
- Outside reset, accept an input byte at a rising edge when the **pre-edge** values satisfy `in_valid && in_ready`.
- `in_last=1` marks the final byte of the input packet and has meaning only when that byte is accepted.
- Packets contain 1 through 8 bytes. A one-byte packet has `in_last=1` on its only byte. The source will not send more than eight accepted bytes for an unfinished packet.
- The first accepted byte after reset, after an accepted final byte, or after abort starts a new packet. There is no separate start signal.
- Input gaps are legal and do not discard or commit an unfinished packet. Continuous `in_valid=1` is legal; every eligible edge accepts another byte.
- Except during reset or abort, the upstream holds `in_valid`, `in_data`, and `in_last` stable while `in_valid && !in_ready`. Abort cancels the unfinished packet and permits the upstream to withdraw an offered but unaccepted byte of that packet.

## Storage and Commit

- Each accepted input byte occupies one of the eight byte entries immediately, even if its packet is not yet complete.
- Bytes of the current unfinished packet are **uncommitted**: they consume storage capacity but must not appear as valid output.
- Accepting a byte with `in_last=1` commits that entire packet, including the newly accepted final byte, after that same edge. Do not add a separate commit cycle.
- Commit changes visibility, not occupancy: committing a packet does not free or duplicate any byte entries.
- Bytes from completed packets must be output in their original packet and byte order. Preserve the final-byte marker for each packet.
- A committed packet may be output over several cycles. Once committed, its bytes remain committed until transferred or reset; abort must not remove them.
- It is legal to output an older completed packet while accepting bytes of a newer unfinished packet.
- Use capacity for exactly eight stored bytes, with no additional input queue or output holding slot beyond those eight entries. Additional control state and final-byte marker bits are allowed.
- Reuse storage as bytes are transferred or an unfinished packet is discarded. Storage must work across any number of wraparounds; physical entry indices must not affect packet order.

## Input Readiness

- Outside reset, generate `in_ready` combinationally and independently of `in_valid`, `in_data`, and `in_last`.
- When `abort=1`, `in_ready` must be 0.
- Otherwise, `in_ready` must be high if and only if the **pre-edge total occupancy** is less than eight. Count both committed and uncommitted bytes.
- Do not use an output transfer on the upcoming edge to admit an input when the FIFO is already full. If occupancy is eight before an edge, input acceptance is blocked on that edge even when an output byte transfers. The freed capacity becomes available after the edge.
- Outside reset, if occupancy is below eight and `abort=0`, accept an offered input even when the output is stalled.
- No particular value of `in_ready` is required while `rst_n=0`.

## Abort and Simultaneous Operations

- On every non-reset rising edge with `abort=1`, discard **all currently stored uncommitted bytes** and cancel the unfinished input packet. Capacity occupied by those bytes becomes free after the edge.
- Abort does not require an unfinished packet to exist. With no uncommitted bytes, it has no effect on stored contents.
- Abort never discards committed bytes, including the remaining bytes of a partially transmitted completed packet.
- Abort blocks input acceptance on its sampling edge, including an offered final byte. Do not commit that offered byte or packet.
- Abort does **not** block output: if a committed output byte has pre-edge `out_valid && out_ready`, transfer it normally on the abort edge.
- Otherwise, input acceptance, packet commit, and output transfer may occur on the same edge. Each transfer uses pre-edge handshake values. Apply their occupancy effects together, without losing a byte or freeing an entry twice.

## Output Behavior

- Outside reset, `out_valid` must be high if and only if at least one committed byte remains stored.
- When valid, output the oldest committed byte and its stored final-byte marker.
- An output byte transfers on a rising edge when pre-edge `out_valid && out_ready` is true. Each transfer frees exactly one byte entry.
- If no committed bytes exist before edge A and edge A accepts a packet's final byte, the packet's first byte becomes valid **after A**. Its earliest output transfer is A+1, even if `out_ready=1` at A.
- After an output transfer, expose the next committed byte after that same edge. Do not insert a bubble between committed bytes or adjacent completed packets.
- While `out_valid && !out_ready`, hold `out_valid`, `out_data`, and `out_last` stable. New input acceptances, commits, and aborts must preserve that pending output.
- Whenever `out_valid=0`, drive `out_data=0` and `out_last=0`. The output must not expose unfinished packet data.
- Combinational reads from stored entries are allowed. Do not bypass unsampled input data directly to valid output.

## Timing Example

Assume reset has completed and the FIFO is empty. All data values are hexadecimal. Inputs and readiness in the table are values **before each rising edge**. The output columns show values **after that edge's register updates and combinational settling**. Transfers use the pre-edge output, not the output shown after the edge.

An input written as `11 / 0` means `in_valid=1`, `in_data=8'h11`, and `in_last=0`. `--` means `in_valid=0`.

| Edge | Input before edge: data / last | `abort` | `out_ready` | `in_ready` before edge | Transfers/action at edge | `out_valid` after edge | `out_data` after edge | `out_last` after edge |
|---|---|---|---|---|---|---|---|---|
| A | 11 / 0 | 0 | 1 | 1 | Accept 11; keep packet uncommitted | 0 | 00 | 0 |
| A+1 | 12 / 1 | 0 | 0 | 1 | Accept 12; commit packet 11,12 | 1 | 11 | 0 |
| A+2 | 21 / 0 | 0 | 1 | 1 | Transfer 11; accept unfinished byte 21 | 1 | 12 | 1 |
| A+3 | 22 / 0 | 0 | 0 | 1 | Accept unfinished byte 22; stall output 12 | 1 | 12 | 1 |
| A+4 | 23 / 1 | 1 | 1 | 0 | Transfer 12; discard 21,22; do not accept 23 | 0 | 00 | 0 |
| A+5 | 31 / 1 | 0 | 1 | 1 | Accept and commit one-byte packet 31 | 1 | 31 | 1 |
| A+6 | -- | 0 | 1 | 1 | Transfer 31 | 0 | 00 | 0 |

## Full-Capacity Boundary Example

Starting empty, accept the eight bytes of one packet at A through A+7, with `in_last=1` only at A+7. No bytes may transfer before A+8 because the packet is uncommitted until after A+7.

- After A+7, occupancy is eight, the first byte is valid output, and `in_ready=0`.
- At A+8, assume `abort=0`, `out_ready=1`, and `in_valid=1`. Transfer the first output byte, but do not accept the offered input because the FIFO was full before the edge.
- After A+8, occupancy is seven and `in_ready=1`. The offered input may be accepted at A+9.
- If an eight-byte packet is committed before an abort edge, abort must preserve it. Abort only removes the newer unfinished packet, if any.

## Task

Implement the module. Be prepared to explain total occupancy versus committed visibility, publication of an entire packet, storage reclamation after abort, simultaneous input/output operations, full-capacity behavior, and wraparound.
