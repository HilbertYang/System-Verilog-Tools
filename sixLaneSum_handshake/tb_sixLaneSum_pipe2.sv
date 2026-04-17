`timescale 1ns/1ps

module tb_sixLaneSum_pipe2;

    logic        clk, rst_n;
    logic        in_valid, out_ready;
    logic [31:0] indata0, indata1, indata2, indata3, indata4, indata5;
    logic        in_ready, out_valid;
    logic [31:0] sum;

    sixLaneSum_pipe2 dut (.*);

    always #5 clk = ~clk;

    task automatic send_inputs(input [31:0] d0, d1, d2, d3, d4, d5);
        indata0 = d0; indata1 = d1; indata2 = d2;
        indata3 = d3; indata4 = d4; indata5 = d5;
        in_valid = 1;
        @(posedge clk);
        while (!in_ready) @(posedge clk);
        @(negedge clk);
        in_valid = 0;
        {indata0, indata1, indata2, indata3, indata4, indata5} = '0;
    endtask

    task automatic expect_output(input [31:0] expected);
        @(posedge clk);
        while (!out_valid) @(posedge clk);
        if (sum !== expected)
            $display("FAIL at time %0t: sum=%0d, expected=%0d", $time, sum, expected);
        else
            $display("PASS at time %0t: sum=%0d", $time, sum);
        @(negedge clk);
    endtask

    initial begin
        clk = 0; rst_n = 0; in_valid = 0; out_ready = 0;
        {indata0, indata1, indata2, indata3, indata4, indata5} = '0;
        repeat(2) @(posedge clk);
        rst_n = 1;
        @(negedge clk);

        // ── Test 1: Basic (2-cycle latency) ───────────────────────────────
        $display("=== Test 1: basic handshake ===");
        out_ready = 1;
        fork
            send_inputs(1, 2, 3, 4, 5, 6);     // expected = 21
            expect_output(21);
        join
        @(negedge clk);

        // ── Test 2: Back-pressure ──────────────────────────────────────────
        $display("=== Test 2: back-pressure ===");
        out_ready = 0;
        fork
            send_inputs(10, 20, 30, 40, 50, 60); // expected = 210
            begin
                repeat(5) @(posedge clk);
                out_ready = 1;
                expect_output(210);
            end
        join
        @(negedge clk);

        // ── Test 3: Back-to-back ───────────────────────────────────────────
        $display("=== Test 3: back-to-back ===");
        out_ready = 1;
        fork
            begin
                send_inputs(100, 200, 300, 400, 500, 600); // sum = 2100
                @(negedge clk);
                send_inputs(1, 1, 1, 1, 1, 1);             // sum = 6
            end
            begin
                expect_output(2100);
                expect_output(6);
            end
        join
        @(negedge clk);

        // ── Test 4: Overflow ───────────────────────────────────────────────
        $display("=== Test 4: overflow ===");
        out_ready = 1;
        fork
            send_inputs(32'hFFFFFFFF, 1, 0, 0, 0, 0); // expected = 0
            expect_output(32'h0);
        join
        @(negedge clk);

        $display("=== All tests done ===");
        $finish;
    end

    initial begin
        #10000;
        $display("TIMEOUT");
        $finish;
    end

endmodule
