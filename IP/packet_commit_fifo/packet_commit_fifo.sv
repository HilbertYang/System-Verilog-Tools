module packet_commit_fifo (
    input  logic       clk,
    input  logic       rst_n,

    input  logic       in_valid,
    output logic       in_ready,
    input  logic [7:0] in_data,
    input  logic       in_last,
    input  logic       abort,

    output logic       out_valid,
    input  logic       out_ready,
    output logic [7:0] out_data,
    output logic       out_last
);
  typedef struct packed{
    logic [7:0] data;
    logic last;
    logic valid;} entry_t;
  entry_t [7:0] ram;

  logic [3:0] rd_ptr, wr_ptr, check_point;
  logic [2:0] rd_addr, wr_addr;
  logic empty, full;
  logic out_hs, in_hs;
  assign empty = rd_ptr == wr_ptr;
  assign full  = (rd_ptr[3] != wr_ptr[3]) && (rd_ptr[2:0] == wr_ptr[2:0]);
  assign in_ready = abort ? '0 : !full;
  assign out_hs = out_valid && out_ready;
  assign in_hs  = in_valid && in_ready;
  assign rd_addr = rd_ptr[2:0];
  assign wr_addr = wr_ptr[2:0];
  assign out_data = out_valid? ram[rd_addr].data : '0;
  assign out_last = out_valid? ram[rd_addr].last : '0;
  
  always_ff@(posedge clk)begin
    if(!rst_n)begin
      rd_ptr <= '0;
      wr_ptr <= '0;
      out_valid <= '0;
      ram <= '0;
      check_point <= '0;
    end else begin
      if(out_hs)begin
        if(rd_ptr ==( check_point-1'b1)) out_valid <= '0;
        ram[rd_addr] <= '0; 
        rd_ptr <= rd_ptr + 1'b1;
      end

      if(abort)begin
        wr_ptr <= check_point;
      end else begin

        if(in_hs)begin
          if(in_last)begin
            ram[wr_addr].last <= 1'b1;
            out_valid <= 1'b1;
            check_point <= wr_ptr + 1'b1;
          end else begin
            ram[wr_addr].last <= '0;
          end
          ram[wr_addr].data <= in_data;
          ram[wr_addr].valid <= 1'b1; 
          wr_ptr <= wr_ptr + 1'b1;
        end
      end
    end
  end
endmodule
