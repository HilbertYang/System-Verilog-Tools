# Byte-Stream Frame Parser: Problem Reconstruction and Review

> Reconstructed from text and screenshots retained in this conversation, rather than transcribed verbatim from the original problem. The following distinguishes the requirements clarified later from assumptions added to form a complete exercise. This document focuses on reconstructing the problem and does not include a complete reference solution.

## 1. What the Problem Tests

Design a synthesizable Verilog/SystemVerilog byte-stream receiver: identify three adjacent SOP bytes in a continuous 8-bit input stream, receive a fixed-length payload, read a trailing check byte, determine whether the payload is valid, and output the data with a completion/valid indication.

The key clarification is: **the three SOPs are three consecutive bytes at the beginning of one frame, not one SOP in each of three consecutive frames.**

The initial answer interpreted the problem as looking for three frame headers at byte positions 0, 16, and 32. That was the interpretation at the time, not the final intended requirement. The final requirement does not need a 32-bit match history to confirm three headers spaced 16 bytes apart.

## 2. Final Format and Limits of the Evidence

The conversation initially showed:

```text
SOP | SOP | SOP | PAYLOAD | CRC (8 bits)
```

A comment in a later screenshot changed this to:

```text
SOP | SOP | SOP | PAYLOAD | parity (16 bits -> 1 parity) (8 bits)
```

The final review should therefore prioritize the **parity-check version**, while retaining the distinction that the field was initially called CRC. CRC-8 and an 8-bit parity field are different algorithms.

| Requirement | Reconstructed interpretation | Certainty |
| --- | --- | --- |
| Input width | 8 bits, received byte by byte | Explicitly stated |
| SOP value | Example: `8'hEF`, supplied through `input [7:0] pattern` | Explicitly stated |
| SOP count | The header consists of three adjacent SOP bytes with the same value | Clarified later |
| Frame contents | Three SOPs, payload, and a trailing check field | Explicitly stated |
| Trailing field length | 8 bits, or one byte | Explicitly stated |
| Last stated check rule | One parity bit for every 16 payload bits | Noted in the screenshot |
| Payload length | This reconstruction uses 16 bytes | Consistent with a 16-element byte array and eight parity bits; original wording was ambiguous |
| Input timing | One valid byte received per clock | Implementation assumption because the original interface had no input valid signal |
| Parity type | Even parity | Not specified in the original problem; assumed by the previous reference implementation |
| Parity-bit ordering | Bit 0 covers the first two payload bytes, and so on | Not specified in the original problem; assumed by the previous reference implementation |
| Output indication | `out_ready` was added in a screenshot | The port appeared, but its complete timing definition was unclear |

### Ambiguity About "16 Bytes"

The original wording, "frames of 16 Byte", might refer to the entire frame length. However, `logic [7:0] out [16]` appeared later, along with a comment specifying one parity bit per 16 bits, eight parity bits in total. If all eight parity bits cover the payload, that payload contains 128 bits, or 16 bytes.

This document therefore uses a **16-byte payload** for the practice exercise:

| Byte offset | Contents |
| --- | --- |
| 0–2 | Three SOP bytes |
| 3–18 | 16-byte payload |
| 19 | One parity byte |

Under this assumption, the entire frame is **20 bytes**. Do not present the 20-byte frame length as confirmed wording from the original problem. If 16 bytes originally referred to the entire frame, subtracting three SOP bytes and one check byte leaves only 12 payload bytes; the check-field mapping would need further clarification.

## 3. Reconstructed Practice Exercise

### Detailed Statement

Design a byte-stream frame parser using synthesizable SystemVerilog.

Input `in` is an 8-bit byte stream. Assume a valid byte is present at every rising clock edge. Input `pattern` specifies the SOP byte, typically `8'hEF`, and remains unchanged during reception.

Each frame consists of the following, in order:

1. Three consecutive SOP bytes, each equal to `pattern`.
2. A 16-byte payload.
3. One 8-bit parity byte.

This practice version uses even parity: each consecutive pair of payload bytes forms a 16-bit data group. Compute the reduction XOR of those 16 data bits as the group's parity bit. The eight groups form one parity byte. Bit 0 covers payload bytes 0 and 1; bit 7 covers bytes 14 and 15.

The module must implement the following behavior:

- Search for three adjacent SOP bytes. Clear the consecutive-match count if a nonmatching byte arrives during the search.
- After receiving the third SOP, begin storing payload bytes at the next clock edge. The three SOPs are not part of the payload.
- Collect all 16 payload bytes in reception order and accumulate parity during reception.
- Interpret the byte immediately following the payload as the received parity; do not store it as payload.
- Compare the calculated and received parity. For this exercise, produce a one-clock-cycle `out_ready` pulse after a successful check.
- On a failed check, do not assert `out_ready` and return to header search. An error output may be added as an interface extension.
- After processing the current frame, support reception of the next frame immediately, without requiring idle cycles between frames.
- Payload bytes may equal `pattern`; do not restart header detection while receiving the payload.
- On reset, clear the reception state, counters, and valid indication. This exercise uses an active-high reset.

If the payload output is used directly as the reception array, it may change during reception; the downstream should read the complete result only when `out_ready` is asserted. If the output must hold the previous valid frame until the next frame passes verification, use an additional reception buffer. That is an extension of the output timing contract.

### Concise Statement

Design a synthesizable SystemVerilog byte-stream frame parser. Assume one valid 8-bit input byte per clock. Each frame consists of three consecutive SOP bytes, a 16-byte payload, and one 8-bit parity byte. The SOP value is supplied through an 8-bit `pattern` input and remains stable during reception.

For this reconstructed exercise, use even parity: each consecutive pair of payload bytes contributes one parity bit, with bit 0 covering payload bytes 0 and 1. Detect the three-byte header, capture the payload, verify the received parity byte, and pulse `out_ready` for one clock only when the payload passes verification. Return to header search after either result and support back-to-back frames. SOP-valued bytes inside the payload must be treated as ordinary data.

The 16-byte payload length, parity convention, parity-bit ordering, and exact output timing are explicit assumptions used to make this exercise fully specified.

## 4. Suggested Interface

The following interface is for the reconstructed exercise, not a verbatim copy of the screenshot interface:

```systemverilog
module bfs (
    input  logic       clk,
    input  logic       reset,
    input  logic [7:0] in,
    input  logic [7:0] pattern,

    output logic [7:0] out [0:15],
    output logic       out_ready
);
    // Implement header detection, payload capture, and parity checking.
endmodule
```

`out [0:15]` contains sixteen 8-bit elements, totaling 128 bits. Here, `out_ready` is a pulse indicating that a valid result is ready, not a downstream backpressure signal.

## 5. Suggested Structure and Common Pitfalls

Use three states:

| State | Meaning of the current input | Completion condition |
| --- | --- | --- |
| `WAIT_SOP` | Search for consecutive SOP bytes | Third SOP received |
| `CAPTURE` | Store payload and accumulate parity | 16th payload byte received |
| `CHECK_PARITY` | Receive and compare the trailing check byte | Return to `WAIT_SOP` after comparison |

Key review points:

1. **The old count is 2 when the third SOP arrives.** With nonblocking assignments, conditions evaluated at the current edge read the value before the update. Thus, `sop_count == 2 && in == pattern` can indicate receipt of the third adjacent SOP.
2. **Do not store that third SOP as payload.** Payload byte 0 arrives at the next edge. This differs from the earlier mistaken interpretation involving a single SOP and confirmation across three spaced frames.
3. **Use a 4-bit byte counter with a range of 0–15.** The last payload byte is identified by 15, not `16*8-1`.
4. **Array and packed-vector indexing have different meanings.** For `logic [7:0] out [0:15]`, `out[index]` is one byte. For `logic [127:0] out`, `out[index]` is only one bit.
5. **The final payload byte must contribute to parity.** If it and the parity byte are handled in different states at adjacent clock edges, the comparison at the next edge sees the updated, complete accumulated parity.
6. **`wait` is a keyword.** Name states with identifiers such as `WAIT_SOP`, and declare the enum type and state registers correctly.
7. **Do not drive input ports.** Increment `byte_count`, rather than writing `in <= in + 1`.
8. **The output must be an actual data interface.** Do not declare only a scalar `output out` and then create a separate internal byte array with the same name.

## 6. Questions to Clarify First During Review

- Does 16 bytes refer to the entire frame or just the payload?
- Is the trailing field CRC-8, or eight parity bits, each covering one 16-bit data group?
- If parity is used, is it odd or even? How are the eight bits ordered?
- If CRC is used, what are the polynomial, initial value, input/output reflection settings, final XOR, and covered data range?
- Is input valid every cycle? If gaps are allowed, add `in_valid`.
- Can the downstream accept each frame immediately when it completes? Must output data be held, or is backpressure needed?
- After a failed check, should the module only resume header search, or also provide an error flag, count, or other output?

Of these points, only the three consecutive leading SOP bytes, byte-stream input, configurable SOP value, and one-byte trailing check were reasonably clear in the later description. Do not treat default choices in reference code as mandatory requirements of the original problem.

## 7. Suggested Self-Test Cases

- Valid frame: three SOPs, 16 payload bytes, and correct parity should produce one valid pulse.
- Incomplete header: a different value after one or two SOPs should restart the count.
- SOP in the payload: it must not start a new frame early.
- Check failure: flip one parity bit; the payload should be rejected.
- Two adjacent valid frames: each should produce its own valid pulse.
- Reset during reception: discard the incomplete frame and resume SOP search.
- Counter boundaries: receive exactly 16 payload bytes, without including the trailing check byte.

Note: parity cannot detect every multibit error. Verification tests should derive expected results from the actual parity rule, rather than assuming that every data modification must be detected.
