`timescale 1ns/1ps

module tb_async_rst_sync_release;

    localparam CLK_PERIOD = 10;

    logic clk, arst_n, srst_n;

    async_rst_sync_release dut (.*);

    initial clk = 0;
    always #(CLK_PERIOD/2) clk = ~clk;

    int pass_count, fail_count;

    task check(input logic exp, input string label);
        if (srst_n === exp) begin
            $display("  PASS  [%s] srst_n=%0b", label, srst_n);
            pass_count++;
        end else begin
            $display("  FAIL  [%s] srst_n=%0b  (expected %0b)", label, srst_n, exp);
            fail_count++;
        end
    endtask

    initial begin
        pass_count = 0; fail_count = 0;
        $display("=== Async-Assert Sync-Release Testbench ===");

        // ---- 1. Assert reset asynchronously (no clock needed)
        $display("\n[1] Async assert: srst_n goes low immediately without clock");
        arst_n = 1; clk = 0;
        #2;
        arst_n = 0;   // assert reset between clock edges
        #1;           // no posedge clk
        check(0, "srst_n low immediately after arst_n=0");

        // ---- 2. Reset holds low across clock edges while arst_n=0
        $display("\n[2] Reset holds during arst_n=0");
        repeat(3) @(posedge clk);
        #1;
        check(0, "srst_n still 0 while arst_n=0");

        // ---- 3. Sync release: needs exactly 2 clock edges
        $display("\n[3] Sync release: takes 2 posedge clk after arst_n=1");
        @(negedge clk);   // deassert between edges to avoid setup issues
        arst_n = 1;
        #1;
        check(0, "srst_n=0 immediately after arst_n=1 (not yet released)");

        @(posedge clk); #1;
        check(0, "srst_n=0 after 1st posedge (still propagating)");

        @(posedge clk); #1;
        check(1, "srst_n=1 after 2nd posedge (released)");

        // ---- 4. Stays released
        $display("\n[4] srst_n stays high after release");
        repeat(4) begin
            @(posedge clk); #1;
            check(1, "srst_n remains 1");
        end

        // ---- 5. Re-assert mid-operation: goes low immediately
        $display("\n[5] Re-assert reset asynchronously mid-run");
        #3;             // between clock edges
        arst_n = 0;
        #1;
        check(0, "srst_n=0 immediately on re-assert");

        // ---- 6. Second release cycle
        $display("\n[6] Second release cycle");
        @(negedge clk);
        arst_n = 1;
        #1;
        check(0, "srst_n=0 right after release");
        @(posedge clk); #1;
        check(0, "srst_n=0 after 1st posedge");
        @(posedge clk); #1;
        check(1, "srst_n=1 after 2nd posedge");

        $display("\n==========================================");
        $display("Result: %0d passed, %0d failed", pass_count, fail_count);
        if (fail_count == 0)
            $display("ALL TESTS PASSED");
        else
            $display("SOME TESTS FAILED");
        $finish;
    end

endmodule
