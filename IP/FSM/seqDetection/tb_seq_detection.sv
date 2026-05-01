`timescale 1ns/1ps

module tb_seq_detection;

    localparam CLK_PERIOD = 10;

    logic clk, rst_n, data_in, detected;

    seq_detection dut (.*);

    initial clk = 0;
    always #(CLK_PERIOD/2) clk = ~clk;

    int pass_count, fail_count;

    // Drive one bit and check detected output
    task automatic drive_and_check(
        input logic  bit_in,
        input logic  expect_detected,
        input string label
    );
        data_in = bit_in;
        @(posedge clk); #1;
        if (detected === expect_detected) begin
            $display("  PASS  [%s] data_in=%0b → detected=%0b", label, bit_in, detected);
            pass_count++;
        end else begin
            $display("  FAIL  [%s] data_in=%0b → detected=%0b  (expected %0b)",
                     label, bit_in, detected, expect_detected);
            fail_count++;
        end
    endtask

    initial begin
        pass_count = 0; fail_count = 0;
        $display("=== Sequence Detector 1011 Testbench ===");

        // reset
        rst_n = 0; data_in = 0;
        @(posedge clk); #1;
        rst_n = 1;

        // ---- 1. Basic match: 1 0 1 1
        $display("\n[1] Basic match: stream 1-0-1-1");
        drive_and_check(1, 0, "1");
        drive_and_check(0, 0, "0");
        drive_and_check(1, 0, "1");
        drive_and_check(1, 1, "1 → detect");

        // ---- 2. No match: 1 0 1 0
        $display("\n[2] No match: stream 1-0-1-0 (after reset)");
        rst_n = 0; @(posedge clk); #1; rst_n = 1;
        drive_and_check(1, 0, "1");
        drive_and_check(0, 0, "0");
        drive_and_check(1, 0, "1");
        drive_and_check(0, 0, "0 → no detect");

        // ---- 3. Overlapping: 1 0 1 1 0 1 1
        //   cycle 4: first  match (1011)
        //   cycle 7: second match (1011, overlapping from the trailing "1")
        $display("\n[3] Overlapping match: stream 1-0-1-1-0-1-1");
        rst_n = 0; @(posedge clk); #1; rst_n = 1;
        drive_and_check(1, 0, "1");
        drive_and_check(0, 0, "0");
        drive_and_check(1, 0, "1");
        drive_and_check(1, 1, "1 → detect#1");
        drive_and_check(0, 0, "0");
        drive_and_check(1, 0, "1");
        drive_and_check(1, 1, "1 → detect#2 (overlap)");

        // ---- 4. All zeros: no match
        $display("\n[4] All zeros: no match");
        rst_n = 0; @(posedge clk); #1; rst_n = 1;
        repeat(8) drive_and_check(0, 0, "0");

        // ---- 5. All ones: no match (1111... never reaches 10)
        $display("\n[5] All ones: no match");
        rst_n = 0; @(posedge clk); #1; rst_n = 1;
        repeat(8) drive_and_check(1, 0, "1");

        // ---- 6. Reset mid-sequence clears state
        $display("\n[6] Reset mid-sequence");
        rst_n = 0; @(posedge clk); #1; rst_n = 1;
        drive_and_check(1, 0, "1");
        drive_and_check(0, 0, "0");
        drive_and_check(1, 0, "1");
        // reset before final bit
        rst_n = 0; @(posedge clk); #1; rst_n = 1;
        drive_and_check(1, 0, "1 after reset → no detect");

        $display("\n==========================================");
        $display("Result: %0d passed, %0d failed", pass_count, fail_count);
        if (fail_count == 0)
            $display("ALL TESTS PASSED");
        else
            $display("SOME TESTS FAILED");
        $finish;
    end

endmodule
