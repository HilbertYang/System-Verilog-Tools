`timescale 1ns/1ps

module tb_one_stage_buffer;

    logic        clk, rst_n;
    logic        in_valid, out_ready;
    logic [31:0] in_data;
    logic        in_ready, out_valid;
    logic [31:0] out_data;

    one_stage_buffer dut (.*);

    always #5 clk = ~clk;

    // Wait until in_ready on posedge, then deassert valid
    task send(input [31:0] d);
        in_valid = 1; in_data = d;
        @(posedge clk);
        while (!in_ready) @(posedge clk);
        #1 in_valid = 0;
    endtask

    initial begin
        clk = 0; rst_n = 0; in_valid = 0; out_ready = 0; in_data = 0;
        repeat(2) @(posedge clk); #1 rst_n = 1;

        // Test 1: send one item, downstream stalls then accepts
        $display("=== Test 1: single transfer ===");
        fork
            send(32'hDEAD_BEEF);
        join_none
        repeat(3) @(posedge clk); #1;
        out_ready = 1;
        @(posedge clk); #1;   // consume
        $display("  consumed: %0h (expect deadbeef)", out_data);
        out_ready = 0;
        @(posedge clk); #1;

        // Test 2: back-to-back with out_ready always high
        $display("=== Test 2: back-to-back ===");
        out_ready = 1;
        for (int i = 1; i <= 4; i++) begin
            in_valid = 1; in_data = i;
            @(posedge clk); #1;
        end
        in_valid = 0;
        @(posedge clk); #1;
        out_ready = 0;
        @(posedge clk); #1;

        // Test 3: simultaneous in and out (same-cycle flow-through)
        $display("=== Test 3: simultaneous in/out ===");
        // pre-fill buffer
        in_valid = 1; in_data = 32'hAAAA_AAAA;
        @(posedge clk); #1;   // buffer gets AAAAs
        in_valid = 0;
        @(posedge clk); #1;
        // present new data and assert out_ready simultaneously
        $display("  out_data before (expect aaaa_aaaa): %0h", out_data);
        in_valid = 1; in_data = 32'hBBBB_BBBB; out_ready = 1;
        @(posedge clk); #1;   // AAAAs go out, BBBBs come in
        in_valid = 0;
        $display("  out_data after  (expect bbbb_bbbb): %0h", out_data);
        out_ready = 1;
        @(posedge clk); #1;   // consume BBBBs
        out_ready = 0;

        repeat(3) @(posedge clk);
        $display("=== All tests done ===");
        $finish;
    end

endmodule
