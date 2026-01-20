module fifo_sync #(
  parameter int WIDTH = 8,
  parameter int DEPTH = 16  // 建议是2的幂：8/16/32...
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

  // full/empty 基于 count（最直观，Day1够用）
  assign empty = (count == 0);
  assign full  = (count == DEPTH);

  // 写/读握手（当不满/不空时才真正执行）
  logic do_write, do_read;
  assign do_write = wr_en && !full;
  assign do_read  = rd_en && !empty;

  // 读数据：同步读（读取发生在时钟沿）
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      rdata <= '0;
    end else if (do_read) begin
      rdata <= mem[rptr];
    end
  end

  // 指针 & 存储 & 计数
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      wptr  <= '0;
      rptr  <= '0;
      count <= '0;
    end else begin
      // 写
      if (do_write) begin
        mem[wptr] <= wdata;
        wptr <= (wptr == DEPTH-1) ? '0 : (wptr + 1);
      end

      // 读
      if (do_read) begin
        rptr <= (rptr == DEPTH-1) ? '0 : (rptr + 1);
      end

      // count更新（同时读写则count不变）
      unique case ({do_write, do_read})
        2'b10: count <= count + 1;
        2'b01: count <= count - 1;
        default: /* 2'b00 or 2'b11 */ count <= count;
      endcase
    end
  end

endmodule
