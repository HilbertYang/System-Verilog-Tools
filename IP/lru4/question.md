# SystemVerilog Interview Problem: Four-Way LRU Replacement Controller

Design a synthesizable controller that tracks the usage order of four storage ways, identified by IDs 0 through 3. When another block needs a replacement location, this controller recommends an invalid way if one exists; otherwise, it recommends the least recently used (LRU) way.

This module stores replacement metadata only. It does not store tags or data, search for a cache hit, or perform a replacement by itself. An external block reports actual uses through the touch port and invalidates ways through a mask.

## Interface

```systemverilog
module lru4 (
    input  logic       clk,
    input  logic       rst_n,

    input  logic       touch_valid,
    input  logic [1:0] touch_way,
    input  logic [3:0] invalidate_mask,

    output logic [3:0] valid_mask,
    output logic [1:0] victim_way
);
```

- `valid_mask[i]=1` means way `i` is valid; zero means it is available as an invalid way.
- `invalidate_mask[i]=1` requests invalidation of way `i`.
- `touch_way` identifies the way actually accessed or filled when `touch_valid=1`.
- All inputs are synchronous to `clk`. Requests use values **before rising edges**. There are no ready signals and no response backpressure.

## Reset

- Use an **active-low synchronous reset**.
- At a rising edge with `rst_n=0`, clear `valid_mask` and initialize the full recency order to **0, 1, 2, 3 from least recent to most recent**.
- Reset overrides invalidations and touches on that edge.
- After reset and combinational settling, `victim_way=0` because every way is invalid and way 0 has the smallest ID.

## Recency Definition

- Maintain a full ordering of all four way IDs, from least recent to most recent. Each ID must appear exactly once, including IDs of currently invalid ways.
- On a touch of way `i`, make `i` the most recently used (MRU) way. Preserve the relative order of the other three ways.
- For example, if the old order is `(1,3,0,2)` and way 0 is touched, the new order is `(1,3,2,0)`.
- Touching the way already at MRU preserves the order.
- Invalidating a way changes its validity but **does not change the recency order**. Repeated invalidation of an already invalid way has no additional effect.
- Use exact LRU order, not round-robin replacement or a tree-based approximation.
- The internal representation is your choice. No specific array layout, rank encoding, or update algorithm is required.

## Invalidation and Touch Semantics

At every non-reset rising edge:

- Invalidate every way selected by `invalidate_mask`. Invalidations work even when no touch is present.
- If `touch_valid=1`, mark `touch_way` valid and promote it to MRU at that same edge.
- A touch of an invalid way is legal: it represents a fill or other use that makes that way valid.
- If a way is both invalidated and touched on the same edge, **touch wins**: it must be valid and MRU after the edge. Other selected ways are still invalidated.
- When `touch_valid=0`, ignore `touch_way` and preserve the recency order.
- With no invalidations and no touch, preserve all state.
- Continuous `touch_valid=1` is legal and represents one touch at every non-reset rising edge. Support consecutive touches without bubbles.
- Repeated touches of the same way must not duplicate or remove any IDs from the order.

## Victim Selection and Timing

- `valid_mask` is registered state. Input changes between rising edges must not change it.
- Generate `victim_way` combinationally from the registered validity and recency state. Do not include unsampled touch or invalidation inputs in the recommendation.
- If any way is invalid, recommend the **lowest-numbered invalid way**, regardless of recency order.
- If all four ways are valid, recommend the least recently used way.
- ID zero is a legal recommendation. There is no separate victim-valid signal because a recommendation always exists.
- Merely recommending a victim does not invalidate it, mark it valid, or change recency. State changes only on sampled touches, invalidations, or reset.
- A touch need not equal the current `victim_way`. It may describe a hit on any valid way or a fill of any way chosen by the surrounding block.
- After an edge changes state, `victim_way` must reflect the new state after combinational settling, without waiting for another edge.
- If an external block samples `victim_way` at an edge, it samples the recommendation based on the **pre-edge state**. The recommendation produced after that edge belongs to the updated state.

## Timing Example

Assume reset has completed. Touch and invalidation columns show inputs **before each named rising edge**. All state and victim columns show values **after that edge's register updates and combinational settling**. Masks are hexadecimal; way IDs are decimal. Recency tuples are written **LRU to MRU** and include invalid ways.

`--` means `touch_valid=0`; otherwise the listed ID is `touch_way` with `touch_valid=1`.

| Edge | Touch before edge | `invalidate_mask` before edge | `valid_mask` after edge | Recency order after edge | `victim_way` after edge |
|---|---|---|---|---|---|
| A | 0 | 0 | 1 | (1,2,3,0) | 1 |
| A+1 | 1 | 0 | 3 | (2,3,0,1) | 2 |
| A+2 | 2 | 0 | 7 | (3,0,1,2) | 3 |
| A+3 | 3 | 0 | F | (0,1,2,3) | 0 |
| A+4 | 0 | 0 | F | (1,2,3,0) | 1 |
| A+5 | 2 | 0 | F | (1,3,0,2) | 1 |
| A+6 | -- | 8 | 7 | (1,3,0,2) | 3 |
| A+7 | 3 | 8 | F | (1,0,2,3) | 1 |
| A+8 | -- | 5 | A | (1,0,2,3) | 0 |
| A+9 | 2 | 0 | E | (1,0,3,2) | 0 |
| A+10 | 0 | 0 | F | (1,3,2,0) | 1 |
| A+11 | 1 | F | 2 | (3,2,0,1) | 0 |
| A+12 | -- | 0 | 2 | (3,2,0,1) | 0 |

At A+6, invalid way 3 is recommended even though way 1 is least recent. At A+7, the touch of way 3 wins over its invalidation. At A+8, ways 0 and 2 are invalid, so choose way 0 even though the full recency order begins with way 1. At A+11, all ways are invalidated, but the same-edge touch leaves way 1 valid and MRU.

## Required Corner Cases

- Zero, one, several, and four valid ways.
- Invalid-way selection when the smallest invalid ID is not the LRU ID.
- Touches of LRU, MRU, and either middle position.
- Repeated touches of one way, alternating touches, and touches of all four ways.
- Invalidation of an already invalid way, multiple invalidations, and all-way invalidation.
- Same-way invalidation and touch on one edge, with other ways invalidated simultaneously.
- Reset concurrent with touch and invalidation requests.
- Input changes between edges and several idle edges: recommendations alone must not update state.

## Task

Implement the module. Be prepared to explain exact recency ordering, preservation of the other ways' relative order, validity versus recency, touch-over-invalidation priority, and pre-edge versus post-edge victim recommendations.
