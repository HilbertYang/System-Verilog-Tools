// HILBERT 04.16.2026
// Testbench for seq_detection: sequence "1101" detector with overlap

`timescale 1ns/1ps

module tb_seq_detection;

    // ── DUT signals ─────────────────────────────────────────────────
    logic clk, rst_n, din, match;

    // ── DUT instantiation ────────────────────────────────────────────
    seq_detection dut (.*);

    // ── Clock: 10ns period ───────────────────────────────────────────
    initial clk = 0;
    always #5 clk = ~clk;

    // ── Task: send one bit and check match ───────────────────────────
    task send_bit(input logic bit_in, input logic expect_match);
        din = bit_in;
        @(posedge clk); #1;
        if (match !== expect_match) begin
            $display("FAIL  din=%b  match=%b  expected=%b  time=%0t",
                     bit_in, match, expect_match, $time);
        end else begin
            $display("PASS  din=%b  match=%b", bit_in, match);
        end
    endtask

    // ── Task: apply async reset ──────────────────────────────────────
    task apply_reset();
        rst_n = 0;
        @(posedge clk); #1;
        if (match !== 0)
            $display("FAIL  reset: match should be 0, got %b", match);
        rst_n = 1;
        @(posedge clk); #1;
    endtask

    // ── Main test ────────────────────────────────────────────────────
    initial begin
        $dumpfile("tb_seq_detection.vcd");
        $dumpvars(0, tb_seq_detection);

        rst_n = 1; din = 0;
        apply_reset();

        // ── Test 1: basic "1101" → single match ──────────────────────
        $display("\n[Test 1] Basic: 1101");
        send_bit(1, 0);
        send_bit(1, 0);
        send_bit(0, 0);
        send_bit(1, 1);  // match here

        // ── Test 2: overlap "1101101" → two matches ───────────────────
        $display("\n[Test 2] Overlap: 1101101");
        apply_reset();
        send_bit(1, 0);
        send_bit(1, 0);
        send_bit(0, 0);
        send_bit(1, 1);  // 1st match
        send_bit(1, 0);
        send_bit(0, 0);
        send_bit(1, 1);  // 2nd match (overlap)

        // ── Test 3: no false match on "1100" ─────────────────────────
        $display("\n[Test 3] No match: 1100");
        apply_reset();
        send_bit(1, 0);
        send_bit(1, 0);
        send_bit(0, 0);
        send_bit(0, 0);  // no match

        // ── Test 4: repeated 1s before match "11101" ─────────────────
        $display("\n[Test 4] Repeated 1s: 11101");
        apply_reset();
        send_bit(1, 0);
        send_bit(1, 0);
        send_bit(1, 0);  // stays in S2
        send_bit(0, 0);
        send_bit(1, 1);  // match

        // ── Test 5: mid-stream async reset kills state ────────────────
        $display("\n[Test 5] Mid-stream reset");
        apply_reset();
        send_bit(1, 0);
        send_bit(1, 0);
        send_bit(0, 0);
        // reset before the final '1'
        rst_n = 0; #3; rst_n = 1;
        @(posedge clk); #1;
        send_bit(1, 0);  // state was reset, no match

        // ── Test 6: all-zeros stream → never match ────────────────────
        $display("\n[Test 6] All zeros");
        apply_reset();
        repeat(8) send_bit(0, 0);

        // ── Test 7: consecutive "1101" non-overlapping ────────────────
        $display("\n[Test 7] Back-to-back 11011101 (no overlap between two)");
        apply_reset();
        send_bit(1, 0);
        send_bit(1, 0);
        send_bit(0, 0);
        send_bit(1, 1);  // 1st match
        send_bit(1, 0);  // start of 2nd, S2
        send_bit(1, 0);  // still S2
        send_bit(0, 0);
        send_bit(1, 1);  // 2nd match

        $display("\n==== All tests done ====");
        $finish;
    end

endmodule
