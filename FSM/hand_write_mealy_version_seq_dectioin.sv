//Hilbert 0.16.2026
module seq_detection_mealy(
	input logic clk,
	input logic din,
	input logic rst_n,
	output logic match);


	localparam logic [1:0]
		S0 = 2'd0,
		S1 = 2'd1,
		S2 = 2'd2,
		S3 = 2'd3;
	logic [1:0] nextState, currState;

	//----stage register-----
	always_ff @(posedge clk or negedge rst_n)begin
		if(!rst_n) begin
			nextState	<= 0;
		end else begin
			currState	<= nextState;
		end	
	end
	//----next state logic---
	always_comb begin
		case(currState)
			S0: nextState = din ? S1 : S0;
			S1: nextState = din ? S2 : S0;
			S2: nextState = din ? S2 : S3;
			S3: nextState = din ? S1 : S0;
			default: nextState = S0;
		endcase	
	end
	//----output function
	always_comb begin
		match = (currState == S3) && din;
	end
	
endmodule
