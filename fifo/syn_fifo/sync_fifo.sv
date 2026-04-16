//4.15.2026 HILBERT
//SYNFIFO
module synfifo#(
	parameter DEPTH		= 16,
	parameter ADDRESS_WIDTH = $clog2(DEPTH),
	parameter DATA_WIDTH	= 64
	)(
	input logic				clk,
	input logic				rst_n,
	input logic [DATA_WIDTH-1:0]		in_data,
	output logic [DATA_WIDTH-1:0]		out_data,
	input logic				wr_en,
	input logic				rd_en,
	output logic				full,
	output logic				empty
	);

	//initmem
	logic [DATA_WIDTH-1:0] mem [0:DEPTH-1];
	//initptr
	logic [ADDRESS_WIDTH:0] rd_ptr;
	logic [ADDRESS_WIDTH:0] wr_ptr;
	logic [ADDRESS_WIDTH-1:0] rd_addr;
	logic [ADDRESS_WIDTH-1:0] wr_addr;
	assign rd_addr = rd_ptr[ADDRESS_WIDTH-1:0];
	assign wr_addr = wr_ptr[ADDRESS_WIDTH-1:0];
	//control logic
	assign full 	= (rd_ptr[ADDRESS_WIDTH] != wr_ptr[ADDRESS_WIDTH])&&
			  (rd_addr == wr_addr);
	assign empty	= rd_ptr == wr_ptr;

	//readlogic
	always @(posedge clk or negedge rst_n)begin
		if(~rst_n)begin
			rd_ptr		<= '0;
			out_data	<= '0;
		end else if(rd_en && !empty)begin
			out_data	<= mem[rd_addr];
			rd_ptr		<= rd_ptr + 1'b1;
		end
	
	end
	
	//writelogic
	always @(posedge clk or negedge rst_n)begin
		if(~rst_n)begin
			wr_ptr		<= '0;
		end else if(wr_en && !full)begin
			mem[wr_addr]	<= in_data;
			wr_ptr		<= wr_ptr + 1'b1;
		end
	
	end
	
endmodule

