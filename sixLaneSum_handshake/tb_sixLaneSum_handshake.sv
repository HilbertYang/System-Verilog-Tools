`timescale 1ns/1ps

module tb_sixLaneSum_handshake;

    logic        clk, rst_n;
    logic        in_valid, out_ready;
    logic [31:0] in_data0, in_data1, in_data2, in_data3, in_data4, in_data5;
    logic        in_ready, out_valid;
    logic [31:0] sum;

    sixLaneSum_handshake dut (.*);

    always #5 clk = ~clk;

    // Helper task: drive one input transaction
    task automatic send_inputs(
        input [31:0] d0, d1, d2, d3, d4, d5
    );
        in_data0 = d0; in_data1 = d1; in_data2 = d2;
        in_data3 = d3; in_data4 = d4; in_data5 = d5;
        in_valid = 1;
        @(posedge clk);
        while (!in_ready) @(posedge clk);
        @(negedge clk);
        in_valid = 0;
        in_data0 = 0; in_data1 = 0; in_data2 = 0;
        in_data3 = 0; in_data4 = 0; in_data5 = 0;
    endtask

    // Helper task: wait for output and check expected sum
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
        {in_data0, in_data1, in_data2, in_data3, in_data4, in_data5} = '0;
        repeat(2) @(posedge clk);
        rst_n = 1;
        @(negedge clk);

        // ── Test 1: Basic handshake (out_ready=1 always) ──────────────────
        $display("=== Test 1: basic handshake ===");
        out_ready = 1;
        fork
            send_inputs(1, 2, 3, 4, 5, 6);      // expected sum = 21
            expect_output(21);
        join
        @(negedge clk);

        // ── Test 2: Back-pressure (out_ready=0, then released) ────────────
        $display("=== Test 2: back-pressure ===");
        out_ready = 0;
        fork
            send_inputs(10, 20, 30, 40, 50, 60); // expected sum = 210
            begin
                repeat(4) @(posedge clk);        // hold back-pressure 4 cycles
                out_ready = 1;
                expect_output(210);
            end
        join
        @(negedge clk);

        // ── Test 3: Back-to-back (simultaneous in/out handshake) ──────────
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

        // ── Test 4: Overflow (wrap-around) ────────────────────────────────
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

    // Timeout watchdog
    initial begin
        #10000;
        $display("TIMEOUT");
        $finish;
    end

endmodule
