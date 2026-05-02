timeunit 1ns;
timeprecision 1ps;

module tb_uart_baud_gen;
    logic clk;
    logic rst_n;
    logic sample_tick;
    logic baud_tick;

    localparam int CLK_FREQ   = 1600;
    localparam int BAUD_RATE  = 10;
    localparam int OVERSAMPLE = 16;

    uart_baud_gen #(
        .CLK_FREQ(CLK_FREQ),
        .BAUD_RATE(BAUD_RATE),
        .OVERSAMPLE(OVERSAMPLE)
    ) dut (
        .clk         (clk),
        .rst_n       (rst_n),
        .sample_tick (sample_tick),
        .baud_tick   (baud_tick)
    );

    initial begin
        $dumpfile("tb_uart_baud_gen.vcd");
        $dumpvars(0, tb_uart_baud_gen);
    end

    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    initial begin
        rst_n = 1'b0;
        repeat (2) @(posedge clk);
        rst_n = 1'b1;

        repeat (1000) @(posedge clk);

        $finish;
    end

endmodule
