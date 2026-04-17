module one_stage_buffer(
	input logic 		clk,
	input logic 		rst_n,
	input logic 		in_valid,
	input logic [31:0] 	in_data,
	input logic 		out_ready,

	output logic 		in_ready,
	output logic 		out_valid,
	output logic [31:0] 	out_data

	
	);

	logic 		buf_full;
	logic [31:0] 	buf_data;

	//output logic
	assign in_ready 	= ~buf_full | out_ready;
	assign out_valid 	=  buf_full;
	assign out_data		=  buf_data;
	//data_loader
	always_ff @(posedge clk or negedge rst_n)begin
		if(~rst_n)begin
			buf_data	<= '0;
			buf_full	<= '0;
		end else begin
			//logic for read
			if (out_ready && out_valid)begin
				buf_data	<= in_data;
				buf_full	<= in_valid;
			end else if (in_valid && in_ready)begin
				buf_data	<= in_data;
				buf_full	<= 1'b1;
			end
		end
	end

endmodule
