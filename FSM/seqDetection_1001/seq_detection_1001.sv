module seq_detection_1001(
	input logic clk,
	input logic rst_n,
	
	input logic data_in,
	
	output logic detected);

	typedef enum logic [2:0] {S0,S1,S2,S3,S4} states;
	states curr_state, next_state;

	always_comb begin
		case(curr_state)
			S0: if (data_in) next_state = S1; else next_state = S0;
		       	S1: if (data_in) next_state = S1; else next_state = S2;
			S2: if (data_in) next_state = S1; else next_state = S3;
			S3: if (data_in) next_state = S4; else next_state = S0;
			S4: if (data_in) next_state = S1; else next_state = S2;
			default: next_state = S0;
		endcase
	end
	
	always_ff @(posedge clk or negedge rst_n)begin
		if(!rst_n)begin
			curr_state <= S0;
		end else begin
			curr_state <= next_state;
		end
	end

	always_comb begin
		detected = (curr_state == S4);
	end
	endmodule
