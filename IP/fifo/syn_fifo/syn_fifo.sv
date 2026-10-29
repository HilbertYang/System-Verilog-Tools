module sync_fifo#(
  parameter depth = 8)(
  input logic clk,
  input logic rst_n,
  input logic wr_en,
  input logic rd_en,
  input logic [7:0] wr_data,
  output logic [7:0] rd_data,
  output logic full,
  output logic empty
  );

  logic [$clog2(depth):0] rd_ptr;
  logic [$clog2(depth):0] wr_ptr;
  logic [depth-1:0][7:0] fifo;
  assign empty = rd_ptr == wr_ptr;
  assign full  = (rd_ptr[$clog2(depth)] == !wr_ptr[$clog2(depth)]) && 
                 (rd_ptr[$clog2(depth)-1:0] == wr_ptr[$clog2(depth)-1:0]);
  always_ff@(posedge clk)begin
    if(!rst_n)begin
      rd_ptr <='0;
      wr_ptr <='0;
      rd_data <= '0;
      fifo <= '0;
    end else begin
      if(wr_en && (!full || (full&&rd_en) ) )begin
        fifo[wr_ptr[$clog2(depth)-1:0]] <= wr_data;
        wr_ptr <= wr_ptr + 1'b1;
      end
      if(rd_en && !empty) begin
        rd_data <= fifo[rd_ptr[$clog2(depth)-1:0]];
        rd_ptr <= rd_ptr + 1'b1;
      end
    end
  end

  endmodule

     


        
