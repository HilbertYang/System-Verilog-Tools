module fifo_sync #(
  parameter int WIDTH = 8,
  parameter int DEPTH = 16  // suggest to be the power of 2 like：8/16/32...
) (
  input  logic             clk,
  input  logic             rst_n,

  input  logic             wr_en,
  input  logic [WIDTH-1:0] wdata,
  output logic             full,

  input  logic             rd_en,
  output logic [WIDTH-1:0] rdata,
  output logic             empty,

  output logic [$clog2(DEPTH+1)-1:0] count
);

  localparam int ADDR_W = $clog2(DEPTH);

  logic [WIDTH-1:0] mem [DEPTH];
  logic [ADDR_W-1:0] wptr, rptr;

  //full and empty flags
  assign empty = (count == 0);
  assign full  = (count == DEPTH);

  // control
  logic do_write, do_read;
  assign do_write = wr_en && !full;
  assign do_read  = rd_en && !empty;//&& is the logical AND operator. However the & is the bitwise AND operator.

  // read data
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      rdata <= '0;
    end else if (do_read) begin
      rdata <= mem[rptr];
    end
  end

  // Wire pointers and count
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      wptr  <= '0;
      rptr  <= '0;
      count <= '0;
    end else begin
      // write
      if (do_write) begin
        mem[wptr] <= wdata;
        wptr <= (wptr == DEPTH-1) ? '0 : (wptr + 1);//cyclic increment
      end

      // read
      if (do_read) begin
        rptr <= (rptr == DEPTH-1) ? '0 : (rptr + 1);
      end

      // update count
      unique case ({do_write, do_read})
        2'b10: count <= count + 1;
        2'b01: count <= count - 1;
        default: /* 2'b00 or 2'b11 */ count <= count;
      endcase
    end
  end

endmodule
