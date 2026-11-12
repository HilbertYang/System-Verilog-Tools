# SystemVerilog Interview Problem: Four-Entry Associative Lookup Table

Design a synthesizable table that stores up to four key/data pairs. Unlike an address-indexed RAM, a lookup searches all valid entries for a matching key.

Each key and each data value is 8 bits wide. For example, after storing key `8'h12` with data `8'hA5`, a lookup of key `8'h12` must return `8'hA5`, regardless of which physical entry holds that pair.

## Interface

```systemverilog
module assoc_table4 (
    input  logic       clk,
    input  logic       rst_n,

    input  logic       update_en,
    input  logic       update_delete,
    input  logic [7:0] update_key,
    input  logic [7:0] update_data,
    output logic       update_ok,

    input  logic       lookup_en,
    input  logic [7:0] lookup_key,
    output logic       lookup_valid,
    output logic       lookup_hit,
    output logic [7:0] lookup_data
);
```

All inputs are synchronous to `clk`. Requests are sampled at rising edges using the values immediately before each edge. Registered outputs become visible after that edge's register updates. No ready signals or output backpressure are required.

## Reset

- Use an **active-low synchronous reset**.
- At a rising edge with `rst_n=0`, invalidate every entry and clear all four outputs: `update_ok`, `lookup_valid`, `lookup_hit`, and `lookup_data`.
- Reset overrides both update and lookup requests on that edge.
- Invalid entries must never match a lookup or an update. Resetting the stored key/data bits is optional; only their validity affects table contents.

## Update Port

On every non-reset edge with `update_en=1`, process exactly one update request. `update_delete=0` requests a write; `update_delete=1` requests a deletion.

For a **write**:

- If a valid entry already has `update_key`, replace its data with `update_data` and set `update_ok=1` after the edge. Do not create a duplicate entry or consume another free entry.
- An existing key must remain writable even when all four entries are valid.
- If the key does not exist and at least one entry is invalid, store the new pair in any invalid entry, mark it valid, and set `update_ok=1` after the edge.
- If the key does not exist and all four entries are valid, reject the write: preserve the entire table and set `update_ok=0`. Do not evict an existing key.

For a **deletion**:

- If a valid entry has `update_key`, invalidate that entry and set `update_ok=1` after the edge. Its capacity is available for a later write.
- If the key does not exist, leave the table unchanged and set `update_ok=0`.
- Ignore `update_data` during deletion.

On a non-reset edge with `update_en=0`, preserve the table and set `update_ok=0`. In particular, `update_delete` alone must not delete anything.

Keys `8'h00` and `8'hFF`, and all data values including zero, are legal. A key must appear in at most one valid entry. Provide capacity for exactly four pairs, with no additional queue or overflow storage.

## Lookup Port

- On a non-reset edge with `lookup_en=1`, search for `lookup_key` and set `lookup_valid=1` immediately after that same edge. No additional response cycle is allowed.
- If the key exists, set `lookup_hit=1` and return its data in `lookup_data`.
- If the key does not exist, set `lookup_hit=0` and `lookup_data=0`.
- `lookup_valid=1` means that a response is present, including a miss. It must not be treated as synonymous with `lookup_hit`.
- On a non-reset edge with `lookup_en=0`, clear `lookup_valid` and hold `lookup_hit` and `lookup_data` unchanged.

## Concurrent Operations and Throughput

- Support one update and one lookup on every clock, including consecutive clocks.
- A lookup always observes table contents **as they existed before its sampling edge**, even when an update occurs on the same edge:
  - A lookup concurrent with insertion of that previously absent key reports a miss.
  - A lookup concurrent with overwrite of that key returns its old data.
  - A lookup concurrent with deletion of that key still reports a hit with its old data.
- The update affects lookups sampled on later edges. Do not forward the current update into the same-edge lookup response.
- Consecutive successful updates may keep `update_ok` high across consecutive cycles. Likewise, consecutive lookup requests may keep `lookup_valid` high; each cycle represents a separate response.

## Timing Example

Assume reset has completed and the table is empty. All request columns show values **before each named rising edge**. All result columns show values **after that edge's register updates**. Keys and data are hexadecimal.

`Write K:D` means `update_en=1`, `update_delete=0`, `update_key=K`, and `update_data=D`. `Delete K` means `update_en=1`, `update_delete=1`, and `update_key=K`. A dash means the corresponding enable is zero.

| Edge | Update request before edge | Lookup request before edge | `update_ok` after edge | `lookup_valid` after edge | `lookup_hit` after edge | `lookup_data` after edge |
|---|---|---|---|---|---|---|
| A | Write 11:A1 | 11 | 1 | 1 | 0 | 00 |
| A+1 | Write 22:B2 | 11 | 1 | 1 | 1 | A1 |
| A+2 | Delete 11 | 11 | 1 | 1 | 1 | A1 |
| A+3 | Write 33:C3 | 11 | 1 | 1 | 0 | 00 |
| A+4 | Write 11:D4 | 11 | 1 | 1 | 0 | 00 |
| A+5 | Write 44:E5 | 11 | 1 | 1 | 1 | D4 |
| A+6 | Write 55:F6 | 55 | 0 | 1 | 0 | 00 |
| A+7 | Write 22:B9 | 22 | 1 | 1 | 1 | B2 |
| A+8 | Delete 33 | 22 | 1 | 1 | 1 | B9 |
| A+9 | Write 55:F6 | 55 | 1 | 1 | 0 | 00 |
| A+10 | Delete 99 | 55 | 0 | 1 | 1 | F6 |
| A+11 | - | - | 0 | 0 | 1 | F6 |

After A+5, all four entries are occupied by keys 11, 22, 33, and 44. The new-key write at A+6 therefore fails, while the existing-key overwrite at A+7 succeeds. Deleting key 33 at A+8 makes room for key 55 at A+9. At A+11, the lookup result fields hold their previous values, but `lookup_valid=0` indicates that there is no new response.

## Task

Implement the module. Be prepared to explain valid-entry matching, prevention of duplicate keys, reuse of deleted capacity, overwrite behavior when full, and same-edge lookup/update timing.
