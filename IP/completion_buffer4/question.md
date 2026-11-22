# SystemVerilog Interview Problem: Four-Entry Completion Reorder Buffer

Design a synthesizable buffer that accepts tasks in order, records their results when they complete in any order, and outputs those results in the original task-acceptance order.

For example, if tasks A, B, and C are accepted in that order, their completion results may arrive in the order B, C, A. The output must still deliver A, B, C. Task execution happens outside this module; the module only reserves entries, records completed results, and preserves output order.

## Interface

```systemverilog
module completion_buffer4 (
    input  logic       clk,
    input  logic       rst_n,

    input  logic       alloc_valid,
    output logic       alloc_ready,
    output logic [1:0] alloc_tag,

    input  logic       complete_valid,
    input  logic [1:0] complete_tag,
    input  logic [7:0] complete_data,

    output logic       out_valid,
    input  logic       out_ready,
    output logic [1:0] out_tag,
    output logic [7:0] out_data
);
```

All inputs are synchronous to `clk`. Evaluate allocation and output handshakes using values immediately **before** each rising edge. State updates become visible **after** that edge, followed by combinational settling. The allocation source captures the pre-edge `alloc_tag` when its request is accepted.

## Reset

- Use an **active-low synchronous reset**.
- On a reset edge, discard all allocated tasks and completed results. Reset overrides allocations, completions, and output transfers on that edge.
- After reset, the buffer is empty, `alloc_ready=1`, `alloc_tag=0`, `out_valid=0`, `out_tag=0`, and `out_data=0`.
- Stored result bits need not be reset if invalid entries cannot appear as valid output.
- Assume the surrounding system cancels pre-reset tasks and does not later send their completion events.

## Allocation and Tags

- Provide capacity for exactly four allocated-but-not-yet-output tasks, including tasks already completed and tasks stalled at the output. Do not add an overflow queue.
- Accept one new task on an edge with `alloc_valid && alloc_ready`. No task payload accompanies allocation; a result byte arrives separately through the completion port.
- Assign tags in a fixed circular sequence: 0, 1, 2, 3, 0, 1, and so on. Advance to the next tag only after an accepted allocation. Tag selection does not depend on which task completes first.
- `alloc_tag` is a combinational indication of the next tag in that sequence. It remains at that value while no allocation is accepted. It is meaningful as an assigned tag only on a successful allocation handshake.
- The accepted task's tag is the value **before** its acceptance edge. The output `alloc_tag` may already indicate the next task's tag after that edge.
- Outside reset, `alloc_ready` must be high exactly when fewer than four tasks are allocated, independently of `alloc_valid`, `complete_valid`, and `out_ready`.
- When all four entries are occupied before an edge, `alloc_ready=0` even if an old output transfers on that edge. The newly freed capacity becomes available after the edge; the earliest new allocation is the next edge.
- A newly allocated entry starts incomplete. Completion alone does not free capacity; only an output transfer or reset does.
- Continuous `alloc_valid=1` is legal. Each eligible rising edge accepts another task. The source keeps `alloc_valid` high while waiting for space.

## Completion Port

- On every non-reset edge with `complete_valid=1`, examine `complete_tag` using the entry's **pre-edge state**.
- If that tag belongs to an allocated, incomplete task, store `complete_data` for it and mark it complete immediately after that same edge.
- Completion events may arrive in any tag order. Support one completion event per clock, including consecutive clocks.
- If the tag is not currently allocated, ignore the completion event without changing any entry.
- If the tagged task is already complete, ignore the duplicate event and preserve its original result. This also applies while that result is stalled or being transferred at the output.
- A completion for a tag first allocated on the same edge is ignored because that entry was unallocated before the edge. The earliest completion for that allocation can be accepted on the next edge.
- There is no completion-ready signal. Every completion event is either recorded or ignored according to these rules.
- Assume the external executor does not send late events belonging to a previous use of a tag after that task has been output. Distinguishing old and new generations of the same two-bit tag is outside this exercise.

## Ordered Output and Backpressure

- The oldest allocated task is the task accepted earliest among those not yet output.
- Assert `out_valid` exactly when the buffer is nonempty and its oldest task is complete. Return that task's tag and result in `out_tag` and `out_data`.
- A later completed task must wait if any earlier task remains incomplete. Never skip an incomplete oldest task.
- Transfer one result at an edge with pre-edge `out_valid && out_ready`. That transfer removes the oldest task and frees its entry.
- After a transfer, the next-oldest task becomes the output candidate immediately after the same edge. If it is already complete, keep `out_valid=1` with its result; do not insert an extra response cycle.
- While `out_valid && !out_ready`, keep `out_valid`, `out_tag`, and `out_data` stable. Other entries may still be allocated or completed if their respective rules permit it.
- If the oldest incomplete task completes at edge A, its result must become valid after edge A. It cannot transfer at edge A because it was not valid before the edge; its earliest transfer is A+1.
- When `out_valid=0`, drive `out_tag=0` and `out_data=0`, regardless of uninitialized or stale stored result bits.
- Output signals may be combinationally derived from registered entry state. Raw completion inputs must not change a pending result before being sampled.

## Concurrent Operations and Idle Behavior

- Support an allocation, a valid completion, and an output transfer on the same edge when their pre-edge conditions permit them. Update all corresponding entries and preserve the remaining tasks' order.
- A retired tag cannot also be reallocated on that edge: when its circular position would be the next allocation tag, the buffer was full before the edge, so allocation is blocked by the full-buffer rule.
- If an allocation and output transfer both occur, total occupancy stays unchanged. A completion event never changes occupancy.
- With no accepted allocation, no applicable completion event, and no output transfer, preserve all task state. Changing `out_ready` alone must not remove or reorder a task.

## Timing Example

Assume reset has completed. In this example `alloc_ready=1` before every listed edge because occupancy never exceeds three.

`Allocate/tag N` means `alloc_valid=1` and the pre-edge `alloc_tag=N`; that allocation is accepted. A dash in that column means `alloc_valid=0`. `N:DD` in the completion column means `complete_valid=1`, `complete_tag=N`, and `complete_data=DD`; a dash means `complete_valid=0`. Tags are decimal and result bytes are hexadecimal.

Request, completion, and readiness columns show values **before the named rising edge**. Transfers use pre-edge outputs. The last column shows the output **after that edge's state updates and combinational settling**. `Invalid` means `out_valid=0`, `out_tag=0`, and `out_data=00`; a pair `(N,DD)` means a valid output with that tag and byte.

| Edge | Allocation before edge | Completion before edge | `out_ready` before edge | Output transferred at edge | Output after edge |
|---|---|---|---|---|---|
| A | Allocate/tag 0 | - | 1 | None | Invalid |
| A+1 | Allocate/tag 1 | - | 1 | None | Invalid |
| A+2 | Allocate/tag 2 | - | 1 | None | Invalid |
| A+3 | - | 2:C2 | 1 | None | Invalid |
| A+4 | - | 1:B1 | 1 | None | Invalid |
| A+5 | - | 0:A0 | 1 | None | (0,A0) |
| A+6 | - | 0:FF | 0 | None | (0,A0) |
| A+7 | - | - | 1 | (0,A0) | (1,B1) |
| A+8 | - | - | 1 | (1,B1) | (2,C2) |
| A+9 | - | - | 1 | (2,C2) | Invalid |

At A+3 and A+4, later tasks have completed, but task 0 blocks output. At A+5, task 0 becomes ready only after the edge; the high `out_ready` does not make it transfer retroactively at that edge. At A+6, the duplicate completion must not replace `A0` with `FF`. After A+9, the next allocation tag is still 3, because exactly three allocations have occurred since reset.

As a separate full-buffer case, allocating tags 0, 1, 2, and 3 without any output transfer must make `alloc_ready=0`. Even if tag 0 transfers at a later edge, an allocation offered on that edge remains blocked. On the following edge, tag 0 may be allocated again and must start incomplete, without inheriting its previous result's completion status.

## Required Corner Cases

- Completing tasks in acceptance order, reverse order, and mixed order.
- An incomplete oldest task blocking several completed later tasks.
- A completed oldest task stalled while other entries receive completions.
- Four occupied entries and a new allocation waiting for an output transfer.
- Simultaneous allocation, completion of another task, and output transfer.
- Completion on the same edge as allocation of that previously unallocated tag.
- Duplicate completions, including one coincident with that task's output transfer.
- Completion of an unallocated tag.
- Tag wraparound and reuse, with completion state cleared for the new task.
- Reset with both incomplete tasks and completed pending results.

## Task

Implement the module using synthesizable SystemVerilog. Be prepared to explain acceptance order versus completion order, occupied versus completed state, tag reuse, occupancy under concurrent operations, and pre-edge handshakes versus post-edge output availability.
