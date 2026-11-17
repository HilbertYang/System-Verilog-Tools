# SystemVerilog Interview Problem: Dual-Port Resource Allocator

Design a synthesizable allocator for eight interchangeable resources, identified by unsigned IDs 0 through 7. Two request ports may each allocate one resource per clock, while a release mask may return any number of resources on the same edge.

For example, the IDs could identify eight transaction slots. Allocating an ID reserves that slot until it is released. The module tracks availability only; it does not store transaction data or track which requester owns each ID.

## Interface

```systemverilog
module resource_allocator8 (
    input  logic            clk,
    input  logic            rst_n,

    input  logic [1:0]      alloc_req,
    input  logic [7:0]      release_mask,

    output logic [1:0]      alloc_ok,
    output logic [1:0][2:0] alloc_id,
    output logic [7:0]      free_mask
);
```

- `alloc_req[i]`, `alloc_ok[i]`, and `alloc_id[i]` belong to allocation port `i`, for `i=0,1`.
- `free_mask[j]=1` means resource ID `j` is free; zero means it is allocated.
- `release_mask[j]=1` requests release of resource ID `j`.
- Two-bit vectors are written in `[1:0]` order. For example, `alloc_req=2'b10` means only port 1 requests an allocation.
- All inputs are synchronous to `clk`. Requests use the values immediately **before** each rising edge. All outputs are registered and become visible **after** that edge's register updates.
- There are no ready signals and no response backpressure. Each request is an allocation attempt on its sampling edge; it either succeeds or fails on that edge, with the response visible immediately afterward.

## Reset

- Use an **active-low synchronous reset**.
- On a rising edge with `rst_n=0`, set `free_mask=8'hFF`, `alloc_ok=0`, and both `alloc_id` fields to zero.
- Reset overrides all releases and allocation requests on that edge.

## Release Semantics

- On each non-reset edge, make every resource selected by `release_mask` available for allocation on that **same edge**.
- Releasing a resource that was already free is legal and has no additional effect. It must not create extra capacity or affect other IDs.
- A resource remains free until successfully allocated. An allocated resource remains allocated until released or reset.
- Releases do not depend on `alloc_req`; they must work even when neither port requests anything.

## Allocation Rules and Priority

- For each edge, consider the resources that were free before the edge together with the resources released on that edge.
- Give **port 0 priority over port 1** when both request resources.
- A requesting port must receive the **lowest-numbered available ID**. For port 1, resources successfully assigned to port 0 on the same edge are no longer available.
- If port 0 does not request anything, it must not reserve or remove an ID. Port 1 then receives the lowest-numbered available ID.
- If exactly one ID is available and both ports request, port 0 succeeds and port 1 fails.
- If at least two IDs are available and both ports request, both must succeed and must receive different IDs.
- If no ID is available for a requesting port, that attempt fails. Do not evict an allocated resource and do not queue the failed request.
- Every successfully allocated ID must have `free_mask[id]=0` after the edge, including an ID released and immediately reallocated on that edge. Thus allocation takes precedence over leaving a selected resource free in the final state.
- Preserve the availability of all resources not affected by a release or successful allocation.
- There is no round-robin policy or fairness requirement; port 0 always has priority.

## Response Timing and Idle Behavior

- Set `alloc_ok[i]=1` immediately after an edge exactly when port `i` requested and successfully allocated a resource at that edge. Return its ID in `alloc_id[i]` after the same edge. Do not add another response edge.
- If port `i` did not request, or its attempt failed, set `alloc_ok[i]=0` and `alloc_id[i]=0` after the edge.
- ID zero is a legal successful allocation. Use `alloc_ok[i]`, not a nonzero ID, to identify success.
- Support up to two allocations on every clock, including consecutive clocks. Continuous `alloc_req[i]=1` represents a fresh attempt on every non-reset rising edge; it does not mean one request held until the bit is lowered.
- A failed request is forgotten after that edge. A later high request bit is a new attempt and may succeed if resources have become available.
- With no releases and no requests, hold `free_mask` unchanged and clear both response fields as specified above.
- Input changes between rising edges must not change any output. In particular, an asserted release bit must not change `free_mask` before it is sampled.

## Timing Example

Assume reset has completed, so all eight resources are free. Request and release columns show inputs **before the named rising edge**. Every output column shows registered values **after that edge has settled**. Eight-bit masks are hexadecimal, two-bit request/success vectors are binary, and IDs are decimal.

The ID tuple is always written as **`(alloc_id[0], alloc_id[1])`**, not packed concatenation order. An ID field is zero whenever its corresponding success bit is zero.

| Edge | `alloc_req` before edge | `release_mask` before edge | `alloc_ok` after edge | IDs `(port 0, port 1)` after edge | `free_mask` after edge |
|---|---|---|---|---|---|
| A | 11 | 00 | 11 | (0,1) | FC |
| A+1 | 11 | 00 | 11 | (2,3) | F0 |
| A+2 | 11 | 00 | 11 | (4,5) | C0 |
| A+3 | 11 | 00 | 11 | (6,7) | 00 |
| A+4 | 11 | 00 | 00 | (0,0) | 00 |
| A+5 | 11 | 04 | 01 | (2,0) | 00 |
| A+6 | 11 | 90 | 11 | (4,7) | 00 |
| A+7 | 10 | 01 | 10 | (0,0) | 00 |
| A+8 | 00 | 40 | 00 | (0,0) | 40 |
| A+9 | 11 | 00 | 01 | (6,0) | 00 |
| A+10 | 01 | 03 | 01 | (0,0) | 02 |
| A+11 | 10 | 02 | 10 | (0,1) | 00 |

At A+5, only ID 2 is released, so port 0 wins it and port 1 fails. At A+6, both newly released IDs can be allocated immediately. At A+7, port 1 successfully receives ID zero; port 0 is inactive. At A+10, ID 1 remains free because only one allocation was requested. At A+11, releasing that already-free ID does not create a second resource.

## Required Corner Cases

- Zero, one, and at least two available resources with both ports requesting.
- Only port 1 requesting, especially when ID zero is the lowest available ID.
- All resources allocated, followed by a release and same-edge allocation.
- Several released IDs, with allocation choosing the smallest IDs rather than release order or previous allocation order.
- Releasing already-free resources, including an all-ones release mask after reset.
- A resource both released and successfully reallocated on the same edge: it must end allocated.
- Consecutive requests and failures followed by successful retries.
- Reset concurrent with release and allocation requests.

## Task

Implement the module using synthesizable SystemVerilog. Be prepared to explain the free-resource bitmap, same-edge release reuse, port and ID priority, prevention of duplicate allocation, and why a registered response can reflect the request sampled at that same edge.
