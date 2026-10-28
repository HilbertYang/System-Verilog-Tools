`timescale 1ns/1ps

module tb_unsigned_restoring_divider;

    localparam int DATA_WIDTH = 8;

    logic                  clk;
    logic                  rst_n;
    logic                  start;
    logic                  ready;
    logic                  busy;
    logic                  done;
    logic [DATA_WIDTH-1:0] dividend;
    logic [DATA_WIDTH-1:0] divisor;
    logic [DATA_WIDTH-1:0] quotient;
    logic [DATA_WIDTH-1:0] remainder;
    logic                  div_by_zero;

    int passed;
    int failed;

    unsigned_restoring_divider #(
        .DATA_WIDTH(DATA_WIDTH)
    ) dut (
        .clk         (clk),
        .rst_n       (rst_n),
        .start       (start),
        .ready       (ready),
        .busy        (busy),
        .done        (done),
        .dividend    (dividend),
        .divisor     (divisor),
        .quotient    (quotient),
        .remainder   (remainder),
        .div_by_zero (div_by_zero)
    );

    always #5 clk = ~clk;

    task automatic run_case(
        input logic [DATA_WIDTH-1:0] test_dividend,
        input logic [DATA_WIDTH-1:0] test_divisor,
        input logic [DATA_WIDTH-1:0] expected_quotient,
        input logic [DATA_WIDTH-1:0] expected_remainder,
        input logic                  expected_div_zero
    );
        begin
            wait (ready);
            @(negedge clk);
            dividend = test_dividend;
            divisor  = test_divisor;
            start    = 1'b1;

            @(negedge clk);
            start = 1'b0;

            wait (done);
            #1;

            if ((quotient === expected_quotient) &&
                (remainder === expected_remainder) &&
                (div_by_zero === expected_div_zero)) begin
                passed++;
                $display("  PASS %0d / %0d = %0d remainder %0d zero=%0b",
                         test_dividend, test_divisor, quotient, remainder,
                         div_by_zero);
            end else begin
                failed++;
                $display("  FAIL %0d / %0d expected q=%0d r=%0d zero=%0b, got q=%0d r=%0d zero=%0b",
                         test_dividend, test_divisor,
                         expected_quotient, expected_remainder,
                         expected_div_zero, quotient, remainder,
                         div_by_zero);
            end

            @(posedge clk);
            #1;
            if (done !== 1'b0) begin
                failed++;
                $display("  FAIL done did not return low after one cycle");
            end
        end
    endtask

    initial begin
        clk         = 1'b0;
        rst_n       = 1'b0;
        start       = 1'b0;
        dividend    = '0;
        divisor     = '0;
        passed      = 0;
        failed      = 0;

        repeat (3) @(posedge clk);
        @(negedge clk);
        rst_n = 1'b1;

        $display("=== Unsigned Restoring Divider Testbench ===");

        run_case(8'd13,  8'd3,  8'd4,   8'd1,  1'b0);
        run_case(8'd100, 8'd10, 8'd10,  8'd0,  1'b0);
        run_case(8'd255, 8'd16, 8'd15,  8'd15, 1'b0);
        run_case(8'd7,   8'd8,  8'd0,   8'd7,  1'b0);
        run_case(8'd0,   8'd9,  8'd0,   8'd0,  1'b0);
        run_case(8'd255, 8'd1,  8'd255, 8'd0,  1'b0);
        run_case(8'd100, 8'd0,  8'd0,   8'd100, 1'b1);

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

