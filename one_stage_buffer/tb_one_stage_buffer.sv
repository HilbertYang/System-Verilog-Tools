`timescale 1ns/1ps

module tb_one_stage_buffer;

    localparam int DATA_WIDTH = 8;
    localparam int CLK_PERIOD = 10;

    logic                  clk, rst_n;
    logic                  in_valid, out_ready;
    logic [DATA_WIDTH-1:0] in_data;
    logic                  in_ready, out_valid;
    logic [DATA_WIDTH-1:0] out_data;

    one_stage_buffer #(.DATA_WIDTH(DATA_WIDTH)) dut (.*);

    initial clk = 0;
    always #(CLK_PERIOD/2) clk = ~clk;

    int pass_count, fail_count;

    task do_reset();
        rst_n = 0; in_valid = 0; out_ready = 0; in_data = '0;
        @(posedge clk); #1;
        rst_n = 1;
        @(posedge clk); #1;
    endtask

    task tick(); @(posedge clk); #1; endtask

    task check_signals(
        input logic exp_in_ready,
        input logic exp_out_valid,
        input logic [DATA_WIDTH-1:0] exp_out_data,
        input string label
    );
        logic ok;
        ok = (in_ready === exp_in_ready) &&
             (out_valid === exp_out_valid) &&
             (exp_out_valid ? (out_data === exp_out_data) : 1'b1);
        if (ok) begin
            $display("  PASS  [%s] in_ready=%0b out_valid=%0b out_data=0x%02h",
                     label, in_ready, out_valid, out_data);
            pass_count++;
        end else begin
            $display("  FAIL  [%s] in_ready=%0b(exp %0b) out_valid=%0b(exp %0b) out_data=0x%02h(exp 0x%02h)",
                     label, in_ready, exp_in_ready, out_valid, exp_out_valid, out_data, exp_out_data);
            fail_count++;
        end
    endtask

    initial begin
        pass_count = 0; fail_count = 0;
        $display("=== One-Stage Buffer Testbench ===");

        // ---- 1. Reset state: empty, ready to accept
        $display("\n[1] After reset");
        do_reset();
        check_signals(1, 0, 'x, "empty → in_ready=1 out_valid=0");

        // ---- 2. Write one item, downstream not ready
        $display("\n[2] Write A, downstream stalls");
        in_valid = 1; in_data = 8'hAA; out_ready = 0;
        tick();
        // buffer now holds AA
        in_valid = 0;
        check_signals(0, 1, 8'hAA, "holding AA: in_ready=0 out_valid=1");

        // ---- 3. Buffer full, upstream also wants to write → should be blocked
        $display("\n[3] Upstream tries to write while full, downstream still stalls");
        in_valid = 1; in_data = 8'hBB; out_ready = 0;
        tick();
        in_valid = 0;
        check_signals(0, 1, 8'hAA, "AA unchanged, BB ignored");

        // ---- 4. Downstream consumes
        $display("\n[4] Downstream consumes AA");
        in_valid = 0; out_ready = 1;
        tick();
        out_ready = 0;
        check_signals(1, 0, 'x, "empty after consume");

        // ---- 5. Same-cycle replace: write and consume simultaneously
        $display("\n[5] Same-cycle replace");
        // first fill buffer
        in_valid = 1; in_data = 8'hCC; out_ready = 0;
        tick(); in_valid = 0;
        check_signals(0, 1, 8'hCC, "holding CC");
        // now replace: upstream sends DD, downstream consumes CC
        in_valid = 1; in_data = 8'hDD; out_ready = 1;
        tick();
        in_valid = 0; out_ready = 0; #1;
        check_signals(0, 1, 8'hDD, "replaced: now holds DD");
        // consume DD
        out_ready = 1; tick(); out_ready = 0;
        check_signals(1, 0, 'x, "empty after consuming DD");

        // ---- 6. Back-to-back writes with downstream always ready
        $display("\n[6] Back-to-back writes, downstream always ready (throughput=1)");
        out_ready = 1;
        for (int i = 0; i < 4; i++) begin
            in_valid = 1; in_data = DATA_WIDTH'(8'hE0 + i);
            tick();
            check_signals(1, 1, DATA_WIDTH'(8'hE0 + i),
                          $sformatf("data=0x%02h pass-through", 8'hE0 + i));
        end
        in_valid = 0; tick();
        out_ready = 0;

        // ---- 7. in_ready is combinational: check before clock edge
        $display("\n[7] in_ready combinational: goes high as soon as out_hs fires");
        do_reset();
        in_valid = 1; in_data = 8'hFF; out_ready = 0;
        tick(); in_valid = 0;
        // buffer full → in_ready=0
        if (in_ready !== 0) begin
            $display("  FAIL  in_ready should be 0 when full");
            fail_count++;
        end else begin
            $display("  PASS  in_ready=0 while buffer full");
            pass_count++;
        end
        // assert out_ready combinatorially → in_ready should go high immediately
        out_ready = 1; #1;
        if (in_ready !== 1) begin
            $display("  FAIL  in_ready should go high combinatorially when out_hs");
            fail_count++;
        end else begin
            $display("  PASS  in_ready=1 combinatorially when out_ready=1");
            pass_count++;
        end
        @(posedge clk); #1;
        out_ready = 0;

        $display("\n==========================================");
        $display("Result: %0d passed, %0d failed", pass_count, fail_count);
        if (fail_count == 0)
            $display("ALL TESTS PASSED");
        else
            $display("SOME TESTS FAILED");
        $finish;
    end

endmodule
