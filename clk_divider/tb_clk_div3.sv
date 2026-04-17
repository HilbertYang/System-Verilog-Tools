module tb_clk_div3;

logic clk, rst_n, clk_div3;

clk_div3 dut (.*);

// 10 ns period
initial clk = 0;
always #5 clk = ~clk;

initial begin
    rst_n = 0;
    @(posedge clk); #1;
    rst_n = 1;
    repeat (18) @(posedge clk);
    $finish;
end

initial begin
    $dumpfile("clk_div3.vcd");
    $dumpvars(0, tb_clk_div3);
    $monitor("t=%0t  clk=%b  cnt=%0d  pos=%b  neg=%b  div3=%b",
             $time, clk, dut.cnt, dut.pos_clk, dut.neg_clk, clk_div3);
end

endmodule
