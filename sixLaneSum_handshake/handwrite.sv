module sixLaneSum_handshake(
	input logic 		clk,
	input logic 		rst_n,
	input logic [31:0] 	indata0, 
	input logic [31:0] 	indata1,
	input logic [31:0] 	indata2,
	input logic [31:0] 	indata3,
	input logic [31:0] 	indata4,
	input logic [31:0] 	indata5,
	input logic		in_valid,
	input logic		out_ready,

	output logic		in_ready,
	output logic		out_valid,
	output logic [31:0]	sum
	);

	logic [31:0]		result;
	assign result 	= indata0 + indata1 + indata2 + indata3 + indata4 + indata5;
	logic in_hs;
	logic out_hs;
	assign in_hs 	= in_ready && in_valid;
	assign out_hs	= out_ready && out_valid;
	
	//state init
	typedef enum logic {
		S0,
		S1
	} states;

	states curr_state, next_state;

	//state register
	always_ff @(posedge clk or negedge rst_n)begin
		if(~rst_n)begin
			curr_state	<= S0;
		end else begin
			curr_state	<= next_state;
		end
	end

	//next state logic 
	always_comb begin
		next_state = curr_state;
		case(curr_state)
			S0: begin 
				if(in_hs)begin
					next_state 	= S1;
				end
			end
			S1: begin
				if(out_hs && ~in_hs)begin
					next_state 	= S0;
				end
			end
			default: next_state	= S0;
		endcase
	end	

	//output logic
	always_ff @(posedge clk or negedge rst_n)begin
		if(~rst_n)begin
			sum		<= '0;
			out_valid	<= '0;
		end else begin
			case(curr_state)
				S0: begin
					if(in_hs)begin
						sum 	<= result;
						out_valid<= 1'b1;
					end
				end
				S1: begin
					if (out_hs)begin
						if(in_hs)begin
							sum	<= result;
						end else begin
							out_valid <= '0;
						end
					end
				end
			endcase
		end
	end

	always_comb begin
		in_ready = out_hs | curr_state==S0;
	end
endmodule

