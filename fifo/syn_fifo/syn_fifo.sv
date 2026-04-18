module syn_fifo#(
	parameter DATA_WIDTH = 8,
	parameter DEPTH	     = 8,
	parameter ADDRESS    = $clog2(DEPTH)
	)(
	input logic clk,
	input logic rst_n,

	input logic wr_en,
	input logic [DATA_WIDTH-1:0] wr_data,
	input logic rd_en,

	output logic [DATA_WIDTH-1:0] rd_data,
	output logic full,
	output logic empty
	);
	//init mem
	logic [DATA_WIDTH-1:0] mem [0:DEPTH-1];
	
	//init ptr
	localparam PTR_ADDR = ADDRESS + 1;
	logic [PTR_ADDR-1:0] wr_ptr;
	logic [PTR_ADDR-1:0] rd_ptr;
	logic [ADDRESS-1:0] wr_addr;
	logic [ADDRESS-1:0] rd_addr;
	assign wr_addr = wr_ptr[ADDRESS-1 :0];
	assign rd_addr = rd_ptr[ADDRESS-1 :0];
	
	//control logic 
	assign empty = (wr_ptr==rd_ptr);
	assign full  = (wr_ptr[PTR_ADDR-1]!=rd_ptr[PTR_ADDR-1]) && (wr_ptr[PTR_ADDR-2:0]==rd_ptr[PTR_ADDR-2:0]);
	
	//write logic
	always_ff @(posedge clk or negedge rst_n)begin
		if(~rst_n)begin
			wr_ptr <= '0;
		end else if (~full&&wr_en) begin
			mem [wr_addr] <= wr_data;
			wr_ptr <= wr_ptr + 1'b1;
		end
	end
	always_ff @(posedge clk or negedge rst_n)begin			
		if(~rst_n)begin
			rd_ptr <= '0;
		end else if (~empty&&rd_en) begin
			rd_data <= mem[rd_addr];
			rd_ptr <= rd_ptr + 1'b1;
		end
	end
	endmodule 
