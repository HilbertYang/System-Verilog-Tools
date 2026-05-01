`timescale 1ns/1ps

// clk period = 10 ns → div3 period = 30 ns, high = 15 ns, low = 15 ns
// Waveform after rst_n release at posedge T0:
//   T0        : pos_clk=1, clk_div3 rises
//   T0+5 (neg): neg_clk=1, clk_div3 stays 1
//   T1=T0+10  : pos_clk=0, clk_div3 stays 1
//   T1+5 (neg): neg_clk=0, clk_div3 falls  ← 15 ns high
//   T2=T0+20  : clk_div3 stays 0
//   T3=T0+30  : pos_clk=1, clk_div3 rises again ← 30 ns period

module tb_clk_div3;

    logic clk, rst_n, clk_div3;

    clk_div3 dut (.*);

    initial clk = 0;
    always #5 clk = ~clk;  // 10 ns period

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

    // Measure period and duty cycle over 3 full output cycles
    real rise0, rise1, rise2, fall0;
    real period_ns, high_ns;

    initial begin
        pass_count = 0; fail_count = 0;
        $display("=== clk_div3 Testbench ===");

        // Test 1: async reset
        rst_n = 0;
        #3;
        check("async reset, no clock", 1'b0, clk_div3);

        // Release reset aligned to posedge
        @(posedge clk); #1;
        rst_n = 1;

        // Capture first three rising edges and first falling edge
        @(posedge clk_div3); rise0 = $realtime;
        @(negedge clk_div3); fall0 = $realtime;
        @(posedge clk_div3); rise1 = $realtime;
        @(posedge clk_div3); rise2 = $realtime;

        period_ns = rise1 - rise0;
        high_ns   = fall0 - rise0;

        $display("  Measured: period=%.1f ns, high=%.1f ns", period_ns, high_ns);

        // Test 2: period should be 30 ns
        if (period_ns == 30.0) begin
            $display("  PASS  period = 30 ns"); pass_count++;
        end else begin
            $display("  FAIL  period = %.1f ns (expected 30.0)", period_ns); fail_count++;
        end

        // Test 3: second period consistent
        if ((rise2 - rise1) == 30.0) begin
            $display("  PASS  period cycle 2 = 30 ns"); pass_count++;
        end else begin
            $display("  FAIL  period cycle 2 = %.1f ns (expected 30.0)", rise2-rise1); fail_count++;
        end

        // Test 4: high time should be 15 ns (50% duty cycle)
        if (high_ns == 15.0) begin
            $display("  PASS  high time = 15 ns (50%% duty cycle)"); pass_count++;
        end else begin
            $display("  FAIL  high time = %.1f ns (expected 15.0)", high_ns); fail_count++;
        end

        // Test 5: mid-run reset → output goes to 0 immediately
        rst_n = 0;
        #2;
        check("mid-run async reset", 1'b0, clk_div3);

        // Test 6–8: resumes correct behavior after re-release
        @(posedge clk); #1;
        rst_n = 1;

        @(posedge clk_div3); rise0 = $realtime;
        @(negedge clk_div3); fall0 = $realtime;
        @(posedge clk_div3); rise1 = $realtime;

        if ((rise1 - rise0) == 30.0) begin
            $display("  PASS  period after re-release = 30 ns"); pass_count++;
        end else begin
            $display("  FAIL  period after re-release = %.1f ns", rise1-rise0); fail_count++;
        end

        if ((fall0 - rise0) == 15.0) begin
            $display("  PASS  high time after re-release = 15 ns"); pass_count++;
        end else begin
            $display("  FAIL  high time after re-release = %.1f ns", fall0-rise0); fail_count++;
        end

        $display("--------------------------------------------------");
        $display("Result: %0d passed, %0d failed", pass_count, fail_count);
        if (fail_count == 0) $display("ALL TESTS PASSED");
        else                 $display("SOME TESTS FAILED");
        $finish;
    end

endmodule
