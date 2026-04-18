module syn_fifo #(
	parameter int DEPTH = 8,
	parameter int DATA_WIDTH = 8
	)(
	input logic clk, 
	input logic rst_n,

	input logic wr_en,
    input logic rd_en,
	input logic [DATA_WIDTH-1:0] wr_data,
	output logic [DATA_WIDTH-1:0] rd_data,
	output logic full,
	output logic empty
	);

	localparam int ADDR = $clog2(DEPTH);
	
	logic [DATA_WIDTH-1:0] 	mem [0:DEPTH-1];
	logic [ADDR:0] 		rd_ptr;
	logic [ADDR:0]		wr_ptr;
	logic [ADDR-1:0] 	rd_addr;
	logic [ADDR-1:0] 	wr_addr;
	
	assign rd_addr 	= rd_ptr[ADDR-1:0];
	assign wr_addr 	= wr_ptr[ADDR-1:0];
	assign empty 	= rd_ptr==wr_ptr;
	assign full 	= (rd_ptr[ADDR]!=wr_ptr[ADDR])&&
			  (rd_ptr[ADDR-1:0]==wr_ptr[ADDR-1:0]);

	always_ff @(posedge clk or negedge rst_n)begin
		if(!rst_n) begin
			{rd_ptr,wr_ptr,rd_data} <= '0;
		end else begin
			if(wr_en && !full) begin
				mem[wr_addr] <= wr_data;
				wr_ptr <= wr_ptr + 1'b1;
			end
			if(rd_en && !empty) begin
				rd_data <= mem[rd_addr];
				rd_ptr <= rd_ptr + 1'b1;
			end
		end
	end
	endmodule
