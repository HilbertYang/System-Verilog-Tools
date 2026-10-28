`timescale 1ns/1ps

module tb_divider_sum;

    localparam int DATA_WIDTH = 8;
    localparam int OUT_WIDTH  = DATA_WIDTH + 2;

    logic clk;
    logic rst_n;

    logic                  in_valid;
    logic [DATA_WIDTH-1:0] a;
    logic [DATA_WIDTH-1:0] b;
    logic [DATA_WIDTH-1:0] c;
    logic [DATA_WIDTH-1:0] d;
    logic [DATA_WIDTH-1:0] e;
    logic [DATA_WIDTH-1:0] f;

    logic                 area_in_ready;
    logic                 area_out_valid;
    logic                 area_out_ready;
    logic [OUT_WIDTH-1:0] area_out;
    logic                 area_div_by_zero;

    logic                 speed_in_ready;
    logic                 speed_out_valid;
    logic                 speed_out_ready;
    logic [OUT_WIDTH-1:0] speed_out;
    logic                 speed_div_by_zero;

    int passed;
    int failed;

    div_sum_area_min #(
        .DATA_WIDTH(DATA_WIDTH)
    ) u_area_min (
        .clk         (clk),
        .rst_n       (rst_n),
        .in_valid    (in_valid),
        .in_ready    (area_in_ready),
        .a           (a),
        .b           (b),
        .c           (c),
        .d           (d),
        .e           (e),
        .f           (f),
        .out_valid   (area_out_valid),
        .out_ready   (area_out_ready),
        .out         (area_out),
        .div_by_zero (area_div_by_zero)
    );

    div_sum_speed_max #(
        .DATA_WIDTH(DATA_WIDTH)
    ) u_speed_max (
        .clk         (clk),
        .rst_n       (rst_n),
        .in_valid    (in_valid),
        .in_ready    (speed_in_ready),
        .a           (a),
        .b           (b),
        .c           (c),
        .d           (d),
        .e           (e),
        .f           (f),
        .out_valid   (speed_out_valid),
        .out_ready   (speed_out_ready),
        .out         (speed_out),
        .div_by_zero (speed_div_by_zero)
    );

    always #5 clk = ~clk;

    task automatic check_result(
        input logic [DATA_WIDTH-1:0] ta,
        input logic [DATA_WIDTH-1:0] tb,
        input logic [DATA_WIDTH-1:0] tc,
        input logic [DATA_WIDTH-1:0] td,
        input logic [DATA_WIDTH-1:0] te,
        input logic [DATA_WIDTH-1:0] tf,
        input logic [OUT_WIDTH-1:0]  expected,
        input logic                  expected_div_zero
    );
        begin
            wait (area_in_ready && speed_in_ready);
            @(negedge clk);
            a        = ta;
            b        = tb;
            c        = tc;
            d        = td;
            e        = te;
            f        = tf;
            in_valid = 1'b1;

            @(negedge clk);
            in_valid = 1'b0;

            wait (speed_out_valid);
            #1;
            if ((speed_out === expected) &&
                (speed_div_by_zero === expected_div_zero)) begin
                passed++;
                $display("  PASS speed out=%0d div_by_zero=%0b", speed_out,
                         speed_div_by_zero);
            end else begin
                failed++;
                $display("  FAIL speed expected=%0d/%0b actual=%0d/%0b",
                         expected, expected_div_zero, speed_out,
                         speed_div_by_zero);
            end

            wait (area_out_valid);
            #1;
            if ((area_out === expected) &&
                (area_div_by_zero === expected_div_zero)) begin
                passed++;
                $display("  PASS area  out=%0d div_by_zero=%0b", area_out,
                         area_div_by_zero);
            end else begin
                failed++;
                $display("  FAIL area  expected=%0d/%0b actual=%0d/%0b",
                         expected, expected_div_zero, area_out,
                         area_div_by_zero);
            end

            // The fast result has been backpressured while the iterative
            // implementation finishes; verify that it was held stable.
            if ((speed_out !== expected) ||
                (speed_div_by_zero !== expected_div_zero)) begin
                failed++;
                $display("  FAIL speed output changed under backpressure");
            end

            area_out_ready  = 1'b1;
            speed_out_ready = 1'b1;
            @(posedge clk);
            @(negedge clk);
            area_out_ready  = 1'b0;
            speed_out_ready = 1'b0;
        end
    endtask

    initial begin
        clk                  = 1'b0;
        rst_n                = 1'b0;
        in_valid             = 1'b0;
        area_out_ready       = 1'b0;
        speed_out_ready      = 1'b0;
        a                    = '0;
        b                    = '0;
        c                    = '0;
        d                    = '0;
        e                    = '0;
        f                    = '0;
        passed               = 0;
        failed               = 0;

        repeat (3) @(posedge clk);
        @(negedge clk);
        rst_n = 1'b1;

        $display("=== Divider Sum: area-min and speed-max ===");

        // 60/5 + 81/9 + 100/4 = 12 + 9 + 25 = 46
        check_result(8'd60, 8'd5, 8'd81, 8'd9, 8'd100, 8'd4,
                     10'd46, 1'b0);

        // 255/1 + 200/10 + 144/12 = 255 + 20 + 12 = 287
        check_result(8'd255, 8'd1, 8'd200, 8'd10, 8'd144, 8'd12,
                     10'd287, 1'b0);

        // Integer division truncates toward zero.
        check_result(8'd17, 8'd3, 8'd29, 8'd5, 8'd50, 8'd7,
                     10'd17, 1'b0);

        // A zero divisor contributes zero and raises the status flag.
        check_result(8'd10, 8'd0, 8'd20, 8'd4, 8'd30, 8'd5,
                     10'd11, 1'b1);

        // Maximum possible sum for DATA_WIDTH=8: 3 * 255 = 765.
        check_result(8'd255, 8'd1, 8'd255, 8'd1, 8'd255, 8'd1,
                     10'd765, 1'b0);

        $display("---------------------------------------------");
        $display("Result: %0d passed, %0d failed", passed, failed);
        if (failed == 0) begin
            $display("ALL TESTS PASSED");
        end else begin
            $fatal(1, "TEST FAILED");
        end

        $finish;
    end

endmodule
