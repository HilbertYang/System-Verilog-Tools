// HILBERT 04.16.2026
// Sequence detector: detect "1101" with overlap, Moore FSM, 3-segment style
//
// State encoding:
//   S0: no match        (reset / mismatch)
//   S1: matched "1"
//   S2: matched "11"
//   S3: matched "110"
//   S4: matched "1101"  → match=1 for this cycle
//
// Overlap handling at S4:
//   The last bit of "1101" is '1'. If din=1 arrives next, that '1' can serve
//   as the first '1' of the next "11xx", so we jump to S2 (not S1), preserving
//   the overlap. Example: "1101101" fires match twice.

module seq_detection (
    input  logic clk,
    input  logic rst_n,
    input  logic din,
    output logic match
);

    // ── State definition ────────────────────────────────────────────
    localparam logic [2:0]
        S0 = 3'd0,   // idle
        S1 = 3'd1,   // matched "1"
        S2 = 3'd2,   // matched "11"
        S3 = 3'd3,   // matched "110"
        S4 = 3'd4;   // matched "1101" → output match

    logic [2:0] curr_state, next_state;

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
            S3: next_state = din ? S4 : S0;
            S4: next_state = din ? S2 : S0;  // overlap: last '1' reused as start of "11"
            default: next_state = S0;
        endcase
    end

    // ── Segment 3: output logic (Moore — depends on curr_state only) ─
    always_comb begin
        match = (curr_state == S4);
    end

endmodule
