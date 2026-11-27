# SystemVerilog Interview Problem: Programmable Input Debouncer

Design a synthesizable filter for a single-bit input that may contain short glitches. The output changes only after enough consecutive samples of the opposite level. Use separate programmable qualification lengths for rising and falling transitions.

For example, with a rising qualification length of 3 and an output currently at 0, one or two consecutive high samples must not change the output. Three consecutive high samples change the output to 1 on the third sample.

## Interface

```systemverilog
module programmable_debouncer (
    input  logic       clk,
    input  logic       rst_n,
    input  logic       sig_in,
    input  logic [7:0] cfg_rise_samples,
    input  logic [7:0] cfg_fall_samples,

    output logic       level,
    output logic       rise_pulse,
    output logic       fall_pulse
);
```

All inputs, including `sig_in`, are already synchronous to `clk`. Synchronization of an external pin is outside this exercise. There is no valid/ready interface: every non-reset rising edge samples `sig_in`.

## Reset and Output Timing

- Use an **active-low synchronous reset**. At a rising edge with `rst_n=0`, set `level=0`, `rise_pulse=0`, and `fall_pulse=0`, and discard all partial qualification progress and captured settings.
- Reset has priority over sampling and transition detection on that edge.
- The three outputs are registered and may change only after rising clock edges. Raw input or configuration changes between edges must not directly change them.
- After reset, a high input starts qualification at the first non-reset rising edge that samples it. Do not require a previously observed low sample or a separate input edge.

## Consecutive-Sample Qualification

- Compare each input sample with the **pre-edge** registered `level`.
- A sample equal to `level` must preserve `level` and cancel all partial qualification progress. A later opposite sample starts a fresh attempt.
- The first sample opposite to `level` starts a new qualification attempt:
  - If `level=0`, capture `cfg_rise_samples` as the required high-sample count.
  - If `level=1`, capture `cfg_fall_samples` as the required low-sample count.
  - Normalize a captured setting of 0 to a required count of **1**. Otherwise, use its unsigned value from 1 through 255.
- Capture the applicable setting only on the first opposite sample of each new attempt. Changes to either configuration input during an active attempt must not alter its required count or restart its progress.
- The first opposite sample counts as **sample 1**, not sample 0. Each subsequent consecutive opposite sample adds one toward the captured requirement.
- On the edge that samples the Nth consecutive opposite value, change `level` to that value immediately after that same edge. Do not wait for another edge.
- When N is 1, the first opposite sample must change `level` immediately after its sampling edge. This applies to both a configuration value of 0 and a value of 1.
- A successful transition ends its qualification attempt and discards that attempt's progress. A subsequent attempt uses a newly captured setting for its own direction.
- Do not accumulate nonconsecutive samples. For a required count of 3, the input sequence `1,1,0,1,1` while `level=0` must not produce a rising transition.
- Both qualification directions must work across arbitrarily long input holds without counter wraparound causing spurious transitions.

## Transition Pulses and Idle Behavior

- On an edge that changes `level` from 0 to 1, set `rise_pulse=1` and `fall_pulse=0` after the edge.
- On an edge that changes `level` from 1 to 0, set `fall_pulse=1` and `rise_pulse=0` after the edge.
- On every edge without a qualified transition, clear both pulses and preserve `level`.
- Never assert both pulses together. A pulse must indicate the level transition performed at its own sampling edge; do not delay it by another cycle.
- Continued input at the accepted level must not generate additional pulses.
- Consecutive edges may produce opposite-direction transitions when both requirements are 1. Do not insert a cooldown cycle or ignore the edge immediately after a transition.

## Timing Example

Assume reset has completed, leaving `level=0` and no qualification attempt active. All input and configuration columns show values **before the named rising edge**. The output columns show values **after that edge's register updates**. Counts are decimal.

| Edge | `sig_in` | `cfg_rise_samples` | `cfg_fall_samples` | Action at edge | `level` after edge | `rise_pulse` after edge | `fall_pulse` after edge |
|---|---|---|---|---|---|---|---|
| A | 1 | 3 | 2 | First high sample; capture rise requirement 3 | 0 | 0 | 0 |
| A+1 | 1 | 1 | 2 | Second high sample; ignore changed rise setting | 0 | 0 | 0 |
| A+2 | 1 | 1 | 2 | Third high sample; qualify rising transition | 1 | 1 | 0 |
| A+3 | 0 | 1 | 2 | First low sample; capture fall requirement 2 | 1 | 0 | 0 |
| A+4 | 1 | 1 | 2 | Input matches level; cancel low-sample progress | 1 | 0 | 0 |
| A+5 | 0 | 1 | 2 | New first low sample; capture fall requirement 2 | 1 | 0 | 0 |
| A+6 | 0 | 1 | 7 | Second low sample; qualify using captured requirement 2 | 0 | 0 | 1 |
| A+7 | 1 | 0 | 7 | First high sample; normalized requirement is 1 | 1 | 1 | 0 |
| A+8 | 0 | 0 | 1 | First low sample; requirement is 1 | 0 | 0 | 1 |
| A+9 | 0 | 9 | 9 | Input matches level; no new transition | 0 | 0 | 0 |

At A+1, changing the rise setting to 1 must not cause an early transition. At A+4, the single high sample cancels the pending falling transition, so the low sample at A+5 starts again at sample 1. At A+7 and A+8, transitions occur on consecutive edges in opposite directions.

## Maximum-Count Boundary

Starting with `level=0` and no attempt active, let edge B sample the first high input with `cfg_rise_samples=255`. Keep the input high thereafter and do not reset:

- B is sample 1.
- B+253 is sample 254; `level` must still be 0 after that edge.
- B+254 is sample 255; set `level=1` and `rise_pulse=1` after that edge.
- At B+255 and all later continuously high samples, keep `level=1` and clear both pulses.

The equivalent rule applies to falling qualification. A reset or matching-level sample before qualification discards the partial count; the next attempt starts from sample 1 and captures a fresh setting.

## Task

Implement the module. Be prepared to explain first-sample counting, configuration capture, cancellation by a matching sample, 0/1 normalization, exact 255-sample timing, and transition pulses without an extra cycle of delay.
