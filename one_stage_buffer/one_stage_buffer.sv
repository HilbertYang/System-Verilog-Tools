module one_stage_buffer #(
	parameter int DATA_WIDTH = 8
	)(
	input logic clk,
	input logic rst_n,
	
	input logic in_valid,
	input logic [DATA_WIDTH-1:0] in_data,
	input logic out_ready,

	output logic in_ready,
	output logic out_valid,
	output logic [DATA_WIDTH-1:0] out_data
	);

	logic in_hs;
	logic out_hs;
	
	assign in_hs = in_valid && in_ready;
	assign out_hs = out_valid && out_ready;
	assign in_ready = !out_valid || out_hs;

	always_ff @(posedge clk or negedge rst_n) begin
		if(!rst_n) begin
			out_valid <= '0;
		end else if(in_hs) begin
			out_valid <= 1'b1;
			out_data <= in_data;
		end else if(out_hs) begin
			out_valid <= 1'b0;
		end
	end
endmodule
			
			
