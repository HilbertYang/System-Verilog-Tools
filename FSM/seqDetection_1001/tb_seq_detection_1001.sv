`timescale 1ns/1ps

module tb_seq_detection_1001;

    logic clk, rst_n, data_in, detected;

    seq_detection_1001 dut (.*);

    initial clk = 0;
    always #5 clk = ~clk;

    int pass_count, fail_count;

    // Apply one bit and capture detected on the following posedge
    task apply(input logic bit_in);
        @(negedge clk);
        data_in = bit_in;
    endtask

    task check(input string desc, input logic expected);
        @(posedge clk); #1;
        if (detected === expected) begin
            $display("  PASS  %s → detected=%0b", desc, detected);
            pass_count++;
        end else begin
            $display("  FAIL  %s → got %0b, expected %0b", desc, detected, expected);
            fail_count++;
        end
    endtask

    // Apply a bit and immediately check on the same posedge
    task send(input logic bit_in, input logic exp, input string desc);
        apply(bit_in);
        check(desc, exp);
    endtask

    task reset_dut();
        rst_n = 0;
        repeat (2) @(posedge clk);
        rst_n = 1;
        @(negedge clk);
        data_in = 0;
    endtask

    initial begin
        pass_count = 0; fail_count = 0;
        data_in = 0; rst_n = 0;
        $display("=== seq_detection_1001 Testbench ===");

        // ---- Test group 1: basic match "1001" ----
        $display("-- Test 1: basic match '1001' --");
        reset_dut();
        send(1, 0, "T1 bit1=1");
        send(0, 0, "T1 bit2=0");
        send(0, 0, "T1 bit3=0");
        send(1, 1, "T1 bit4=1 → detected");

        // ---- Test 2: no match "1000" ----
        $display("-- Test 2: no match '1000' --");
        reset_dut();
        send(1, 0, "T2 bit1=1");
        send(0, 0, "T2 bit2=0");
        send(0, 0, "T2 bit3=0");
        send(0, 0, "T2 bit4=0 → no detect");

        // ---- Test 3: no match "1010" ----
        $display("-- Test 3: no match '1010' --");
        reset_dut();
        send(1, 0, "T3 bit1=1");
        send(0, 0, "T3 bit2=0");
        send(1, 0, "T3 bit3=1");
        send(0, 0, "T3 bit4=0 → no detect");

        // ---- Test 4: leading 1s then match "11001" ----
        $display("-- Test 4: '11001' --");
        reset_dut();
        send(1, 0, "T4 bit1=1");
        send(1, 0, "T4 bit2=1");
        send(0, 0, "T4 bit3=0");
        send(0, 0, "T4 bit4=0");
        send(1, 1, "T4 bit5=1 → detected");

        // ---- Test 5: overlapping "1001001" → detect at bit4 and bit7 ----
        $display("-- Test 5: overlapping '1001001' --");
        reset_dut();
        send(1, 0, "T5 bit1=1");
        send(0, 0, "T5 bit2=0");
        send(0, 0, "T5 bit3=0");
        send(1, 1, "T5 bit4=1 → first detect");
        send(0, 0, "T5 bit5=0");
        send(0, 0, "T5 bit6=0");
        send(1, 1, "T5 bit7=1 → second detect (overlap)");

        // ---- Test 6: all zeros → never detect ----
        $display("-- Test 6: all zeros --");
        reset_dut();
        send(0, 0, "T6 b1=0");
        send(0, 0, "T6 b2=0");
        send(0, 0, "T6 b3=0");
        send(0, 0, "T6 b4=0");
        send(0, 0, "T6 b5=0");

        // ---- Test 7: all ones → never detect ----
        $display("-- Test 7: all ones --");
        reset_dut();
        send(1, 0, "T7 b1=1");
        send(1, 0, "T7 b2=1");
        send(1, 0, "T7 b3=1");
        send(1, 0, "T7 b4=1");
        send(1, 0, "T7 b5=1");

        // ---- Test 8: reset in middle of sequence ----
        $display("-- Test 8: reset mid-sequence --");
        reset_dut();
        send(1, 0, "T8 bit1=1");
        send(0, 0, "T8 bit2=0");
        // reset here
        @(negedge clk); rst_n = 0;
        @(posedge clk); #1;
        if (detected === 1'b0) begin
            $display("  PASS  T8 reset mid-seq → detected=0"); pass_count++;
        end else begin
            $display("  FAIL  T8 reset mid-seq → detected=%0b, expected 0", detected); fail_count++;
        end
        rst_n = 1;
        // continues from S0
        send(1, 0, "T8 after reset bit1=1");
        send(0, 0, "T8 after reset bit2=0");
        send(0, 0, "T8 after reset bit3=0");
        send(1, 1, "T8 after reset bit4=1 → detected");

        // ---- Test 9: long sequence "100101001" — detects at pos 4 and pos 9 ----
        // Trace: 1→S1, 0→S2, 0→S3, 1→S4(det), 0→S2, 1→S1, 0→S2, 0→S3, 1→S4(det)
        $display("-- Test 9: '100101001' --");
        reset_dut();
        send(1, 0, "T9 b1=1");
        send(0, 0, "T9 b2=0");
        send(0, 0, "T9 b3=0");
        send(1, 1, "T9 b4=1 → first detect");
        send(0, 0, "T9 b5=0");
        send(1, 0, "T9 b6=1");
        send(0, 0, "T9 b7=0");
        send(0, 0, "T9 b8=0");
        send(1, 1, "T9 b9=1 → second detect");

        // ---- Test 10: detected asserted exactly 1 cycle ----
        $display("-- Test 10: detected held for 1 cycle only --");
        reset_dut();
        send(1, 0, "T10 b1=1");
        send(0, 0, "T10 b2=0");
        send(0, 0, "T10 b3=0");
        send(1, 1, "T10 b4=1 → detected high");
        send(0, 0, "T10 b5=0 → detected back to 0");

        $display("--------------------------------------------------");
        $display("Result: %0d passed, %0d failed", pass_count, fail_count);
        if (fail_count == 0) $display("ALL TESTS PASSED");
        else                 $display("SOME TESTS FAILED");
        $finish;
    end

endmodule
