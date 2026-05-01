module async_rst_sync_release(
	input logic clk,
	input logic arst_n,
	
	output logic srst_n);
	
	logic ff1, ff0;
	assign srst_n = ff1;
	always @(posedge clk or negedge arst_n)begin
		if(!arst_n)begin
			ff1 <= 0;
			ff0 <= 0;
		end else begin
			ff1 <= ff0;
			ff0 <= 1'b1;
		end
	end
	endmodule
