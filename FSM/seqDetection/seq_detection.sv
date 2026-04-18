module seq_detection(
	input logic clk,
	input logic rst_n,
	input logic data_in,

	output logic detected
	);

	typedef enum logic [2:0] {S0,S1,S2,S3,S4} state;
	state currState, nextState;
	//next state logic
	always_comb begin
		case(currState)
			S0: if (data_in) nextState = S1; else nextState = S0;
			S1: if (data_in) nextState = S1; else nextState = S2;
			S2: if (data_in) nextState = S3; else nextState = S0;
			S3: if (data_in) nextState = S4; else nextState = S2;
			S4: if (data_in) nextState = S1; else nextState = S2;
			default: nextState = S0;
		endcase
	end
       	//state
	always_ff @(posedge clk or negedge rst_n)begin
		if(!rst_n)begin
			currState <= S0;
		end else begin
			currState <= nextState;
		end
	end
	
	//output
	always_comb begin
		detected = (currState == S4);
	end 
endmodule



