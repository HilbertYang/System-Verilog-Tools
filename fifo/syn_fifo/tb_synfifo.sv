`timescale 1ns/1ps
module tb_synfifo;

	logic clk;
	logic rst_n;

	logic wr_en;
	logic [63:0] in_data; 
	logic full;

	logic rd_en;
	logic [63:0] out_data;
	logic empty;

	synfifo dut(
		.clk		(clk),
		.rst_n		(rst_n),
		
		.wr_en		(wr_en),
		.in_data	(in_data),
		.full		(full),

		.rd_en		(rd_en),
		.out_data	(out_data),
		.empty		(empty)
	);


	//clk
	initial clk = 1'b0;	
	always #5 clk = ~clk;
	
	//other signal initial
	initial begin
		rst_n 	= 1'b0;
		wr_en 	= 1'b0;
		in_data = 64'd0;
		rd_en	= 1'b0;
	
		#20;
		rst_n = 1'b1;
	
		//write into it
		#30;
		wr_en	= 1'b1;
		in_data	= 64'h1111222233334444;
		#10;
		wr_en	= 1'b0;
		#10;
		rd_en	= 1'b1;
		#10;
		rd_en	= 1'b0;

		//finish
		#10
		$finish;
	end

	initial begin
		$dumpfile("tb_synfifo.vcd");
		$dumpvars(0,tb_synfifo);
	end

endmodule
