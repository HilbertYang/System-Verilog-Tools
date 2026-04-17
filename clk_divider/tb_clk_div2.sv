`timescale 1ns/1ps

module tb_clk_div2;

    logic clk, rst_n, clk_div2;

    clk_div2 dut (.*);

    initial clk = 0;
    always #5 clk = ~clk;  // 100 MHz

    initial begin
        $dumpfile("clk_div2.vcd");
        $dumpvars(0, tb_clk_div2);

        rst_n = 0;
        repeat (3) @(posedge clk);
        rst_n = 1;

        repeat (10) @(posedge clk);
        $finish;
    end

    always @(posedge clk_div2) $display("t=%0t  clk_div2 rising edge", $realtime);
    always @(negedge clk_div2) $display("t=%0t  clk_div2 falling edge", $realtime);

endmodule
