// HILBERT 04.16.2026
// Sequence detector "1101" — Mealy FSM, 3-segment style
//
// Mealy vs Moore:
//   Moore:  output depends only on state          → needs 5 states (S0–S4)
//   Mealy:  output depends on state + current din → needs 4 states (S0–S3)
//           match fires combinationally when din='1' is seen while in S3
//
// State encoding:
//   S0: no valid prefix
//   S1: matched "1"
//   S2: matched "11"
//   S3: matched "110"   ← match=1 when din=1 arrives here
//
// Overlap at S3+din=1:
//   The '1' that completes "1101" is also the first '1' of the next attempt,
//   so next_state = S1 (not S0). Example: "1101101" fires match twice.

module seq_detection_mealy (
    input  logic clk,
    input  logic rst_n,
    input  logic din,
    output logic match
);

    localparam logic [1:0]
        S0 = 2'd0,
        S1 = 2'd1,
        S2 = 2'd2,
        S3 = 2'd3;

    logic [1:0] curr_state, next_state;

    // ── Segment 1: state register (async active-low reset) ──────────
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            curr_state <= S0;
        else
            curr_state <= next_state;
    end

    // ── Segment 2: next-state logic (combinational) ──────────────────
    always_comb begin
        case (curr_state)
            S0: next_state = din ? S1 : S0;
            S1: next_state = din ? S2 : S0;
            S2: next_state = din ? S2 : S3;  // "111…" stays in S2
            S3: next_state = din ? S1 : S0;  // overlap: completing '1' → back to S1
            default: next_state = S0;
        endcase
    end

    // ── Segment 3: output logic (Mealy — state + din) ────────────────
    // match is combinational; registered version would need an extra FF
    always_comb begin
        match = (curr_state == S3) && din;
    end

endmodule
