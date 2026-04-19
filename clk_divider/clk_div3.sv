module clk_div3(
	input logic clk,
	input logic rst_n,
	
	output logic clk_div3);
	
	logic pos_clk, neg_clk;
	assign clk_div3 = pos_clk | neg_clk;
	
	localparam int POS = 0;
	localparam int NEG = 1;
	localparam int RET = 2;

	logic [1:0] cnt;

	always_ff @(posedge clk or negedge rst_n)begin
		if(!rst_n) begin
			cnt <= '0;
		end else if(cnt == RET)begin
			cnt <= '0;
		end else begin
			cnt <= cnt + 1'b1;
		end
	end

	always_ff @(posedge clk or negedge rst_n)begin
		if(!rst_n) begin
			pos_clk <= '0;
		end else if(cnt == POS)begin
		      	pos_clk <= 1'b1;
		end else begin
			pos_clk <= '0;	
		end
	end

	always_ff @(negedge clk or negedge rst_n)begin
		if(!rst_n) begin
			neg_clk <= '0;
		end else if(cnt == NEG)begin
		      	neg_clk <= 1'b1;
		end else begin
			neg_clk <= '0;	
		end
	end

	endmodule

