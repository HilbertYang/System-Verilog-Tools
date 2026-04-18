module sixLaneSum_handshake(
	input logic clk,
	input logic rst_n,
	
	input logic in_valid,
	input logic [31:0]	in_data0,in_data1,in_data2,in_data3,in_data4,in_data5,
	input logic out_ready,
	
	output logic in_ready,
	output logic out_valid,
	output logic [31:0] sum
	);

	logic out_hs,in_hs;
	assign out_hs = out_valid&&out_ready;
	assign in_hs = in_valid&&in_ready;
	assign in_ready = !out_valid || out_hs;

	logic [31:0]	result;
	assign result = in_data0 + in_data1 + in_data2 + in_data3 + in_data4 + in_data5;

	always_ff @(posedge clk or negedge rst_n) begin
		if(!rst_n) begin
			out_valid <= '0;
		end else if(in_hs) begin
			sum <= result;
			out_valid <= 1'b1;
		end else if (out_hs) begin
			out_valid <= 1'b0;
		end
	end
	endmodule

