module sixLaneSum_pipe2(
	input logic clk,
	input logic rst_n,
	
	input logic in_valid,
	input logic [31:0] in_data0,in_data1,in_data2,in_data3,in_data4,in_data5,
	input logic out_ready,
	
	output logic in_ready,
	output logic out_valid,
	output logic [31:0] sum);

	logic [31:0] ps01, ps23, ps45;
	logic [31:0] result;

	assign ps01 = in_data0 + in_data1;
	assign ps23 = in_data2 + in_data3;
	assign ps45 = in_data4 + in_data5;

	logic [31:0] ps01_ff, ps23_ff, ps45_ff;

	assign result = ps01_ff + ps23_ff + ps45_ff;

	logic in_hs,out_hs,ff_hs;
	logic ff_valid, ff_ready;
	
	assign in_hs = in_valid && in_ready;
	assign ff_hs = ff_valid && ff_ready;
	assign out_hs = out_valid && out_ready;
	assign ff_ready = !out_valid || out_hs;
	assign in_ready = !ff_valid || ff_hs;

	always_ff @(posedge clk or negedge rst_n)begin
		if(!rst_n) begin
			ff_valid <= '0;
			out_valid <= '0;
		end else if (in_hs) begin
			ff_valid <= 1'b1;
			ps01_ff <= ps01;
			ps23_ff <= ps23;
			ps45_ff <= ps45;
		end else if (ff_hs) begin
			out_valid <= 1'b1;
			ff_valid  <= 1'b0;
			sum	<= result;
		end else if (out_hs) begin
			out_valid <= '0;
		end
	end
	endmodule
		

			

