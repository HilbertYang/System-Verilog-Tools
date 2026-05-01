`timescale 1ns/1ps

module tb_sixLaneSum_pipe2;

    localparam CLK_PERIOD = 10;

    logic        clk, rst_n;
    logic        in_valid, out_ready;
    logic [31:0] in_data0, in_data1, in_data2, in_data3, in_data4, in_data5;
    logic        in_ready, out_valid;
    logic [31:0] sum;

    sixLaneSum_pipe2 dut (.*);

    initial clk = 0;
    always #(CLK_PERIOD/2) clk = ~clk;

    int pass_count, fail_count;

    task do_reset();
        rst_n = 0; in_valid = 0; out_ready = 0;
        {in_data0,in_data1,in_data2,in_data3,in_data4,in_data5} = '0;
        @(posedge clk); #1; rst_n = 1; @(posedge clk); #1;
    endtask

    task send(input logic [31:0] d0,d1,d2,d3,d4,d5);
        in_valid = 1;
        in_data0=d0; in_data1=d1; in_data2=d2;
        in_data3=d3; in_data4=d4; in_data5=d5;
        @(posedge clk); #1;
        in_valid = 0;
    endtask

    task check_sum(input logic [31:0] exp, input string label);
        if (out_valid === 1 && sum === exp) begin
            $display("  PASS  [%s] sum=0x%08h", label, sum);
            pass_count++;
        end else begin
            $display("  FAIL  [%s] out_valid=%0b sum=0x%08h (expected 0x%08h)",
                     label, out_valid, sum, exp);
            fail_count++;
        end
    endtask

    logic [31:0] exp_sum;

    initial begin
        pass_count = 0; fail_count = 0;
        $display("=== sixLaneSum_pipe2 Testbench ===");

        // ---- 1. Reset state
        $display("\n[1] After reset");
        do_reset();
        if (out_valid === 0 && in_ready === 1) begin
            $display("  PASS  out_valid=0 in_ready=1");
            pass_count++;
        end else begin
            $display("  FAIL  out_valid=%0b in_ready=%0b", out_valid, in_ready);
            fail_count++;
        end

        // ---- 2. Two-cycle latency: result arrives after 2 clocks
        $display("\n[2] Two-cycle latency: 1+2+3+4+5+6=21");
        out_ready = 0;
        send(1,2,3,4,5,6);
        // cycle 1: stage1 has partial sums, out_valid still 0
        if (out_valid === 0) begin
            $display("  PASS  out_valid=0 after 1st cycle (stage1 filling)");
            pass_count++;
        end else begin
            $display("  FAIL  out_valid should be 0 after 1st cycle");
            fail_count++;
        end
        // cycle 2: stage2 completes
        @(posedge clk); #1;
        check_sum(32'd21, "sum=21 after 2nd cycle");

        // ---- 3. Result holds while out_ready=0
        $display("\n[3] Result holds while downstream stalls");
        @(posedge clk); #1;
        check_sum(32'd21, "still holding sum=21");

        // ---- 4. Consume and verify pipeline drains
        $display("\n[4] Consume");
        out_ready = 1; @(posedge clk); #1; out_ready = 0;
        if (out_valid === 0) begin
            $display("  PASS  out_valid=0 after consume");
            pass_count++;
        end else begin
            $display("  FAIL  out_valid should be 0");
            fail_count++;
        end

        // ---- 5. One-at-a-time: send, wait 2 cycles for result, verify, consume
        $display("\n[5] One-at-a-time: verify each result after 2-cycle latency");
        do_reset();
        for (int i = 1; i <= 4; i++) begin
            out_ready = 0;
            in_valid = 1;
            in_data0=32'(i); in_data1=32'(i); in_data2=32'(i);
            in_data3=32'(i); in_data4=32'(i); in_data5=32'(i);
            @(posedge clk); #1;   // stage1 latches
            in_valid = 0;
            @(posedge clk); #1;   // stage2 latches, out_valid=1
            exp_sum = 32'(i) * 6;
            check_sum(exp_sum, $sformatf("i=%0d sum=%0d", i, exp_sum));
            out_ready = 1; @(posedge clk); #1; out_ready = 0;
        end

        // ---- 6. Backpressure: downstream stalls mid-pipeline
        $display("\n[6] Backpressure: stage2 stalls, stage1 should also stall");
        do_reset();
        out_ready = 0;
        send(5,5,5,5,5,5);       // sum=30, enters stage1
        @(posedge clk); #1;       // stage2 now holds 30, out_valid=1
        check_sum(32'd30, "sum=30 in stage2");
        // send another while output stalls
        send(10,10,10,10,10,10);  // sum=60, enters stage1
        // stage1 should be stalled too (s1_valid=1, s1_ready=0)
        @(posedge clk); #1;
        check_sum(32'd30, "sum=30 still held (backpressure)");
        // release downstream
        out_ready = 1; @(posedge clk); #1;
        check_sum(32'd60, "sum=60 after backpressure release");
        out_ready = 1; @(posedge clk); #1; out_ready = 0;

        // ---- 7. Overflow wraps in 32-bit
        $display("\n[7] Overflow: 6 x 32'hFFFFFFFF");
        do_reset();
        out_ready = 1;
        send(32'hFFFFFFFF,32'hFFFFFFFF,32'hFFFFFFFF,
             32'hFFFFFFFF,32'hFFFFFFFF,32'hFFFFFFFF);
        @(posedge clk); #1;
        exp_sum = 32'hFFFFFFFF * 6;
        check_sum(exp_sum, "overflow wrap");

        $display("\n==========================================");
        $display("Result: %0d passed, %0d failed", pass_count, fail_count);
        if (fail_count == 0) $display("ALL TESTS PASSED");
        else                 $display("SOME TESTS FAILED");
        $finish;
    end

endmodule
