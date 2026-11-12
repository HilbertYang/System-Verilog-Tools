# SystemVerilog Interview Problem: Programmable PWM Generator

Design a synthesizable PWM (pulse-width modulation) generator. Software may supply new period and duty settings while the generator is running, but a configuration update must never shorten or extend the current PWM frame.

## Interface

```systemverilog
module pwm_generator (
    input  logic       clk,
    input  logic       rst_n,

    input  logic       cfg_valid,
    input  logic [7:0] cfg_period,
    input  logic [7:0] cfg_duty,

    output logic       pwm,
    output logic       frame_start
);
```

All inputs are synchronous to `clk`. Input values are sampled immediately before each rising edge. Output values specified after an edge refer to the values after register updates and combinational settling. No generated clock or clock-domain crossing is required.

## PWM Frames

- A frame contains `P` complete clock intervals, where `P` is the active period in the range 1 through 255.
- Number the intervals within a frame with a conceptual phase from 0 through `P-1`. This phase describes required behavior; it need not be an output port.
- The active duty `D` is the number of high intervals at the beginning of each frame, with `0 <= D <= P`.
- During a frame, `pwm=1` exactly when the phase is less than `D`; otherwise `pwm=0`.
- Thus `D=0` produces a continuously low output, and `D=P` produces a continuously high output, including across consecutive frames with the same settings.
- On each non-reset rising edge, advance to the next phase. When the phase immediately before the edge is `P-1`, that edge is a **frame boundary**: finish the old frame and start phase 0 of the next frame.
- Determine whether an edge is a boundary using the **old active period and old phase**, even when a new configuration is supplied on that edge.
- Assert `frame_start=1` immediately after every boundary edge. Clear it after every other non-reset edge. For `P=1`, every edge is a boundary, so `frame_start` may remain high across consecutive cycles.
- The generator runs continuously; there is no enable input or idle state.

## Reset

- Use an **active-low synchronous reset**.
- On an edge with `rst_n=0`, set the active period to 1, active duty to 0, and phase to 0. Discard any pending configuration and set both outputs to 0.
- Reset overrides configuration acceptance and normal frame progression on that edge.
- After reset is released, the first non-reset rising edge is a boundary of the initial one-interval frame. A configuration supplied on that first edge can therefore take effect immediately after it.

## Configuration Acceptance and Normalization

- On every non-reset edge with `cfg_valid=1`, accept one complete period/duty pair. There is no ready signal.
- Normalize each accepted pair as follows:
  - If `cfg_period=0`, use a period of 1; otherwise use `cfg_period`.
  - If `cfg_duty` exceeds that normalized period, clamp the duty to that period; otherwise use `cfg_duty`.
- Period and duty always belong to the same accepted pair; never combine fields from different requests.
- Consecutive configuration requests are legal, including continuous `cfg_valid=1`. Each edge accepts another pair.
- Ignore `cfg_period` and `cfg_duty` when `cfg_valid=0`.

## Applying Configuration at Boundaries

- The active settings must remain unchanged throughout the current frame.
- A request accepted on a non-boundary edge becomes pending for the next boundary. It must not restart the phase or change the current frame's waveform.
- Keep capacity for **one pending pair**. If another request arrives before a boundary, replace the pending pair with the newer request. Intermediate configurations may be superseded; this is not a FIFO.
- At a boundary, choose the settings for the frame beginning at that edge in this order:
  1. If `cfg_valid=1` at that edge, use the newly accepted pair, overriding any older pending pair.
  2. Otherwise, if a pending pair exists, use it.
  3. Otherwise, retain the old active settings.
- After a boundary, no request remains pending: any pending pair was either applied or superseded. A request applied directly at a boundary must not be replayed at a later boundary.
- The selected settings govern `pwm` starting immediately after that boundary edge, with the new phase equal to 0. Do not add an extra cycle of latency.
- With no requests, continue generating frames using the active settings indefinitely.
- Here, preserving the waveform means preserving complete clock intervals and frame lengths. No sub-cycle analog glitch or gate-delay guarantee is required.

## Timing Example

Assume a reset edge has completed. All numbers below are unsigned decimal. A dash means `cfg_valid=0`; a pair `(P,D)` means `cfg_valid=1` with the listed raw input values.

The request column contains inputs **before the named rising edge**. The boundary column is determined from the **pre-edge active state**. Every column labeled "after edge" describes the new state or outputs **after that edge has settled**. Active settings and phase are explanatory values, not additional required ports.

| Edge | Request before edge | Boundary at this edge? | Active `(P,D)` after edge | Phase after edge | `pwm` after edge | `frame_start` after edge |
|---|---|---|---|---|---|---|
| A | (4,2) | Yes | (4,2) | 0 | 1 | 1 |
| A+1 | (3,1) | No | (4,2) | 1 | 1 | 0 |
| A+2 | - | No | (4,2) | 2 | 0 | 0 |
| A+3 | - | No | (4,2) | 3 | 0 | 0 |
| A+4 | (2,2) | Yes | (2,2) | 0 | 1 | 1 |
| A+5 | (3,1) | No | (2,2) | 1 | 1 | 0 |
| A+6 | - | Yes | (3,1) | 0 | 1 | 1 |
| A+7 | - | No | (3,1) | 1 | 0 | 0 |
| A+8 | - | No | (3,1) | 2 | 0 | 0 |
| A+9 | (0,255) | Yes | (1,1) | 0 | 1 | 1 |
| A+10 | - | Yes | (1,1) | 0 | 1 | 1 |
| A+11 | (1,0) | Yes | (1,0) | 0 | 0 | 1 |

The frame beginning at A lasts exactly four clock intervals, from A to A+4. The request at A+1 does not change that frame and is superseded by the newer request at A+4. The request at A+5 takes effect at A+6. At A+9, normalize the period before clamping the duty, producing `(1,1)`.

## Required Corner Cases

- Duty equal to zero, equal to the period, and greater than the period.
- Raw period equal to zero, one, and 255.
- Multiple requests within one frame: only the latest pair is applied at its boundary.
- A request exactly on a boundary, with and without an older pending pair.
- Switching between longer and shorter periods without changing the length of the old frame.
- Consecutive boundary requests while the active period is one.
- Reset during a frame with a pending request: discard that request and restore the reset state.

## Task

Implement the module. Be prepared to explain frame-length counting, pending versus active configuration, same-edge boundary/request priority, and the 0% and 100% duty cases.
