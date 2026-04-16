// HILBERT 04.16.2026
// Testbench for seq_detection_mealy
//
// Mealy timing model (one cycle):
//   1. din is driven (state is stable from previous edge)
//   2. #1  → combinational output (match) settles  ← sample here
//   3. @(posedge clk)  → state register advances
//
// Contrast with Moore tb:
//   Moore: drive din → posedge → #1 → sample match (output is registered)
//   Mealy: drive din → #1 → sample match → posedge (output is combinational)

`timescale 1ns/1ps

module tb_seq_detection_mealy;

    logic clk, rst_n, din, match;

    seq_detection_mealy dut (.*);

    initial clk = 0;
    always #5 clk = ~clk;

    // Drive din, let combinational settle, check match, then advance state
    task send_bit(input logic bit_in, input logic expect_match);
        din = bit_in;
        #1;  // combinational settle (before posedge)
        if (match !== expect_match)
            $display("FAIL  din=%b  match=%b  expected=%b  time=%0t",
                     bit_in, match, expect_match, $time);
        else
            $display("PASS  din=%b  match=%b", bit_in, match);
        @(posedge clk);  // advance state
    endtask

    task apply_reset();
        rst_n = 0; din = 0;
        @(posedge clk);
        if (match !== 0)
            $display("FAIL  reset: match should be 0, got %b", match);
        rst_n = 1;
        @(posedge clk);  // one clean cycle after reset deasserted
    endtask

    initial begin
        $dumpfile("tb_seq_detection_mealy.vcd");
        $dumpvars(0, tb_seq_detection_mealy);

        rst_n = 1; din = 0;
        apply_reset();

        // ── Test 1: basic "1101" ──────────────────────────────────────
        $display("\n[Test 1] Basic: 1101");
        send_bit(1, 0);
        send_bit(1, 0);
        send_bit(0, 0);
        send_bit(1, 1);  // match fires combinationally (state=S3, din=1)

        // ── Test 2: overlap "1101101" → two matches ───────────────────
        $display("\n[Test 2] Overlap: 1101101");
        apply_reset();
        send_bit(1, 0);
        send_bit(1, 0);
        send_bit(0, 0);
        send_bit(1, 1);  // 1st match → next_state=S1 (overlap)
        send_bit(1, 0);
        send_bit(0, 0);
        send_bit(1, 1);  // 2nd match

        // ── Test 3: no false match on "1100" ─────────────────────────
        $display("\n[Test 3] No match: 1100");
        apply_reset();
        send_bit(1, 0);
        send_bit(1, 0);
        send_bit(0, 0);
        send_bit(0, 0);

        // ── Test 4: repeated 1s "11101" ──────────────────────────────
        $display("\n[Test 4] Repeated 1s: 11101");
        apply_reset();
        send_bit(1, 0);
        send_bit(1, 0);
        send_bit(1, 0);  // stays S2
        send_bit(0, 0);
        send_bit(1, 1);  // match

        // ── Test 5: mid-stream async reset ───────────────────────────
        $display("\n[Test 5] Mid-stream reset");
        apply_reset();
        send_bit(1, 0);
        send_bit(1, 0);
        send_bit(0, 0);
        rst_n = 0; #3; rst_n = 1;
        @(posedge clk);
        send_bit(1, 0);  // state was reset, no match

        // ── Test 6: all zeros ─────────────────────────────────────────
        $display("\n[Test 6] All zeros");
        apply_reset();
        repeat(8) send_bit(0, 0);

        // ── Test 7: back-to-back "11011101" ──────────────────────────
        $display("\n[Test 7] Back-to-back: 11011101");
        apply_reset();
        send_bit(1, 0);
        send_bit(1, 0);
        send_bit(0, 0);
        send_bit(1, 1);  // 1st match → S1
        send_bit(1, 0);  // S1→S2
        send_bit(1, 0);  // S2→S2
        send_bit(0, 0);  // S2→S3
        send_bit(1, 1);  // 2nd match

        $display("\n==== All tests done ====");
        $finish;
    end

endmodule
