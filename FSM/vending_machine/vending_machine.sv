module vending_machine(
	input logic clk,
	input logic rst_n,
	input logic nickel,
	input logic dime,

	output logic dispense,
	output logic change
	);

	typedef enum logic[2:0] {S0,S5,S10,S15,S20} states;
	states current_state, next_state;
	//Next state logic
	always_comb begin
		case(current_state)
			S0: begin
				if(nickel) begin
					next_state = S5;
				end else if (dime) begin
					next_state = S10;
				end else begin
					next_state = S0;
				end
			end
			S5: begin
				if(nickel) begin
					next_state = S10;
				end else if (dime) begin
					next_state = S15;
				end else begin
					next_state = S0;
				end
			end
			S10: begin
				if(nickel) begin
					next_state = S15;
				end else if (dime) begin
					next_state = S20;
				end else begin
					next_state = S0;
				end
			end
			S15: 	next_state = S0;
			S20:    next_state = S0;
		endcase
	end
	//stage
	always_ff @(posedge clk or negedge rst_n) begin
		if(!rst_n)begin
			current_state <= 0;
		end else begin
			current_state <= next_state;
		end
	end
	
	//output logic
	always_comb begin
		dispense = (current_state == S20) || (current_state==S15);
		change = (current_state == S20);
	end
endmodule
