`timescale 1ns/1ps

module tb_sixLaneSum_handshake;

    localparam CLK_PERIOD = 10;

    logic        clk, rst_n;
    logic        in_valid, out_ready;
    logic [31:0] in_data0, in_data1, in_data2, in_data3, in_data4, in_data5;
    logic        in_ready, out_valid;
    logic [31:0] sum;

    sixLaneSum_handshake dut (.*);

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
        logic [31:0] ref_sum;
        ref_sum = in_data0+in_data1+in_data2+in_data3+in_data4+in_data5;
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
        $display("=== sixLaneSum_handshake Testbench ===");

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

        // ---- 2. Basic sum, downstream stalls
        $display("\n[2] Basic sum: 1+2+3+4+5+6=21, downstream stalls");
        out_ready = 0;
        send(1,2,3,4,5,6);
        check_sum(32'd21, "sum=21");
        // result must hold while out_ready=0
        @(posedge clk); #1;
        check_sum(32'd21, "still holding sum=21");

        // ---- 3. Downstream consumes
        $display("\n[3] Downstream consumes");
        out_ready = 1; @(posedge clk); #1; out_ready = 0;
        if (out_valid === 0) begin
            $display("  PASS  out_valid=0 after consume");
            pass_count++;
        end else begin
            $display("  FAIL  out_valid should be 0 after consume");
            fail_count++;
        end

        // ---- 4. Same-cycle replace
        $display("\n[4] Same-cycle replace");
        out_ready = 0;
        send(10,10,10,10,10,10);  // sum=60
        check_sum(32'd60, "holding 60");
        // replace while downstream consumes
        out_ready = 1;
        in_valid = 1;
        in_data0=1; in_data1=1; in_data2=1; in_data3=1; in_data4=1; in_data5=1;
        @(posedge clk); #1;
        in_valid = 0; out_ready = 0; #1;
        check_sum(32'd6, "replaced with 6");

        // ---- 5. Back-to-back, downstream always ready (throughput test)
        $display("\n[5] Back-to-back, downstream always ready");
        out_ready = 1; @(posedge clk); #1; // drain
        out_ready = 1;
        for (int i = 0; i < 4; i++) begin
            in_valid = 1;
            in_data0=32'(i*10); in_data1=32'(i*10); in_data2=32'(i*10);
            in_data3=32'(i*10); in_data4=32'(i*10); in_data5=32'(i*10);
            @(posedge clk); #1;
            exp_sum = 32'(i*10) * 6;
            if (out_valid === 1 && sum === exp_sum) begin
                $display("  PASS  [iter %0d] sum=0x%08h", i, sum);
                pass_count++;
            end else begin
                $display("  FAIL  [iter %0d] sum=0x%08h (exp 0x%08h)", i, sum, exp_sum);
                fail_count++;
            end
        end
        in_valid = 0;

        // ---- 6. Overflow wraps correctly (32-bit)
        $display("\n[6] Overflow: 6 x 32'hFFFFFFFF");
        out_ready = 1; @(posedge clk); #1;
        send(32'hFFFFFFFF,32'hFFFFFFFF,32'hFFFFFFFF,
             32'hFFFFFFFF,32'hFFFFFFFF,32'hFFFFFFFF);
        exp_sum = 32'hFFFFFFFF * 6; // wraps in 32-bit
        check_sum(exp_sum, "overflow wrap");
        out_ready = 1; @(posedge clk); #1; out_ready = 0;

        $display("\n==========================================");
        $display("Result: %0d passed, %0d failed", pass_count, fail_count);
        if (fail_count == 0) $display("ALL TESTS PASSED");
        else                 $display("SOME TESTS FAILED");
        $finish;
    end

endmodule
