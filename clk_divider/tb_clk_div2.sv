`timescale 1ns/1ps

module tb_clk_div2;

    logic clk, rst_n, clk_div2;

    clk_div2 dut (.*);

    initial clk = 0;
    always #5 clk = ~clk;  // 10 ns period, 100 MHz

    int pass_count, fail_count;

    task check(input string desc, input logic expected, input logic actual);
        if (actual === expected) begin
            $display("  PASS  %s → %0b", desc, actual);
            pass_count++;
        end else begin
            $display("  FAIL  %s → got %0b, expected %0b", desc, actual, expected);
            fail_count++;
        end
    endtask

    initial begin
        pass_count = 0; fail_count = 0;
        $display("=== clk_div2 Testbench ===");

        // Test 1: async reset asserted → output must be 0 immediately (no clock needed)
        rst_n = 0;
        #3;
        check("async reset, no clock", 1'b0, clk_div2);

        // Test 2–7: toggle behavior after reset release
        @(posedge clk); #1;
        rst_n = 1;
        check("cycle 0 after reset", 1'b0, clk_div2);

        @(posedge clk); #1;
        check("cycle 1: should be 1", 1'b1, clk_div2);

        @(posedge clk); #1;
        check("cycle 2: should be 0", 1'b0, clk_div2);

        @(posedge clk); #1;
        check("cycle 3: should be 1", 1'b1, clk_div2);

        @(posedge clk); #1;
        check("cycle 4: should be 0", 1'b0, clk_div2);

        @(posedge clk); #1;
        check("cycle 5: should be 1", 1'b1, clk_div2);

        // Test 8: mid-run reset → output goes to 0 immediately
        rst_n = 0;
        #2;
        check("mid-run async reset", 1'b0, clk_div2);

        // Test 9–10: resumes toggling after re-release
        @(posedge clk); #1;
        rst_n = 1;
        check("resume cycle 0", 1'b0, clk_div2);

        @(posedge clk); #1;
        check("resume cycle 1", 1'b1, clk_div2);

        $display("--------------------------------------------------");
        $display("Result: %0d passed, %0d failed", pass_count, fail_count);
        if (fail_count == 0) $display("ALL TESTS PASSED");
        else                 $display("SOME TESTS FAILED");
        $finish;
    end

endmodule
