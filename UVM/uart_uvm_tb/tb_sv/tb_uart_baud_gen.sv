timeunit 1ns;
timeprecision 1ps;

module tb_uart_baud_gen;
    logic clk;
    logic rst_n;
    logic baud_tick;

    localparam int CLK_FREQ  = 100_000_000;
    localparam int BAUD_RATE = 115_200;

    uart_baud_gen #(
        .CLK_FREQ(CLK_FREQ),
        .BAUD_RATE(BAUD_RATE)
    ) dut (
        .clk       (clk),
        .rst_n     (rst_n),
        .baud_tick (baud_tick)
    );

    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    initial begin
        rst_n = 1'b0;
        repeat (2) @(posedge clk);
        rst_n = 1'b1;

        repeat (2000) @(posedge clk);

        $finish;
    end

endmodule