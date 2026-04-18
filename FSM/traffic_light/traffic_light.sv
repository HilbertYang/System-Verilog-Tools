module traffic_light #(
	parameter int GREEN_TIME = 4,
	parameter int YELLOW_TIME = 2
	)(
	input logic clk,rst_n,
	output logic [1:0] ns_light,ew_light
	);
	typedef enum logic [1:0] {S0,S1,S2,S3} states;
	states curr_state, next_state;
	localparam logic [1:0] RED = 2'b00;
	localparam logic [1:0] YELLOW = 2'b01;
	localparam logic [1:0] GREEN = 2'b10;
	logic [1:0] counter;
	
	always_comb begin
		case(curr_state)
			S0: next_state = S1;
			S1: next_state = S2;
			S2: next_state = S3;
			S3: next_state = S0;
			default: next_state = S0;
		endcase
	end
	
	always_ff @(posedge clk or negedge rst_n)begin
		if(~rst_n) begin
			curr_state <= S0;
			counter <= '0;
		end else begin
			if((curr_state == S0)&&(counter == (GREEN_TIME-1)))begin
				curr_state <= next_state;
				counter <= '0;	
			end else if ((curr_state == S1)&&(counter == (YELLOW_TIME-1)))begin
				curr_state <= next_state;
				counter <= '0;
			end else if ((curr_state == S2) && (counter == (GREEN_TIME-1)))begin
				curr_state <= next_state;
				counter <= '0;
			end else if ((curr_state == S3) && (counter == (YELLOW_TIME-1)))begin
				curr_state <= next_state;
				counter <= '0;
			end else begin
				counter <= counter + 2'b1;
			end
		end
	end

	always_comb begin
		if(curr_state == S0) begin
			ns_light = GREEN;
			ew_light = RED;
		end else if (curr_state == S1) begin
			ns_light = YELLOW;
			ew_light = RED;
		end else if (curr_state == S2) begin
			ns_light = RED;
			ew_light = GREEN;
		end else if (curr_state == S3) begin
			ns_light = RED;
			ew_light = YELLOW;
		end else begin
			ns_light = RED;
			ew_light = RED;
		end
	end
	endmodule
