//4.11.2025 Hilbert
//system verilog version for syn_fifo
module syn_fifo #(
    parameter DEPTH = 8,
    parameter DATA_WIDTH = 64,
    parameter ADDRESS = $clog2(DEPTH)
)(
    input   logic                           clk,
    input   logic                           rst_n,

    input   logic                           wr_en,
    input   logic    [DATA_WIDTH-1:0]       wr_data,
    output  logic                           full,

    input   logic                           rd_en,
    output  logic    [DATA_WIDTH-1:0]       rd_data,
    output  logic                           empty

);
    //internal use
    logic [DATA_WIDTH-1:0]   mem [0:ADDRESS-1];
    logic [ADDRESS:0]   wr_pointer;
    logic [ADDRESS:0]   rd_pointer;

    logic [ADDRESS-1:0] wr_addr = wr_pointer [ADDRESS-1:0];
    logic [ADDRESS-1:0] rd_addr = rd_pointer [ADDRESS-1:0]; 

    //logic for empty and full
    assign full     =   (wr_pointer[ADDRESS] != rd_pointer[ADDRESS]) && 
                        (wr_pointer[ADDRESS-1:0] == wr_pointer[ADDRESS-1:0]);
    assign empty    =   wr_pointer == rd_pointer;

    //syn_read
    always @(posedge clk or negedge rst_n)begin
        if (!rst_n)begin
            rd_pointer  <=  '0;
            rd_data     <=  '0;
        end else if (rd_en && !empty) begin
            rd_data     <=  mem[rd_addr];
            rd_pointer  += rd_pointer + 1'b1;
        end
    end

    //syn_write
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            wr_pointer  <=  '0;
        end else if (wr_en && !full) begin
            mem[wr_addr]<=wr_data;
            wr_pointer  += wr_pointer + 1'b1; 
        end
        
    end

    
    
endmodule




