module completion_buffer4 (
    input  logic       clk,
    input  logic       rst_n,

    input  logic       alloc_valid,
    output logic       alloc_ready,
    output logic [1:0] alloc_tag,

    input  logic       complete_valid,
    input  logic [1:0] complete_tag,
    input  logic [7:0] complete_data,

    output logic       out_valid,
    input  logic       out_ready,
    output logic [1:0] out_tag,
    output logic [7:0] out_data
);
    typedef struct packed{
      logic       valid;
      logic [7:0] data;
    } entry_t;

  entry_t [3:0] task_queue;

  logic [2:0] rd_ptr, wr_ptr;
  logic alloc_hs;
  logic out_hs;
  logic empty;
  logic full;
  
  logic [2:0] used_count;
  logic [1:0] tag_offset;
  logic       complete_allcated;
  assign used_count = wr_ptr - rd_ptr;
  assign tag_offset = complete_tag - rd_ptr[1:0];
  assign complete_allcated = {1'b0, tag_offset} < used_count; 
  assign empty = rd_ptr == wr_ptr;
  assign full  = (rd_ptr[1:0] == wr_ptr[1:0]) && (rd_ptr[2] != wr_ptr[2]);

  assign alloc_ready = !full;
  assign alloc_hs = alloc_ready && alloc_valid;
  assign out_hs   = out_ready && out_valid;
  assign out_valid = !empty && task_queue[rd_ptr[1:0]].valid;
  assign out_data  = out_valid ? task_queue[rd_ptr[1:0]].data : '0;
  assign out_tag   = out_valid ? rd_ptr[1:0] : '0;
  
  always_ff@(posedge clk)begin
      if(!rst_n)begin
        alloc_tag   <= '0;
        rd_ptr      <= '0;
        wr_ptr      <= '0;
        task_queue  <= '0;
      end else begin
        if(alloc_hs)begin
          task_queue[wr_ptr[1:0]].valid <= '0;
          wr_ptr <= wr_ptr + 1'b1;
          alloc_tag <= wr_ptr[1:0] + 1'b1;
        end
        if(complete_valid&&(task_queue[complete_tag].valid==0)&&complete_allcated)begin
          task_queue[complete_tag].valid <= 1'b1;
          task_queue[complete_tag].data  <= complete_data;
        end
        if(out_hs)begin
          rd_ptr <= rd_ptr + 1'b1;
          task_queue[rd_ptr[1:0]].valid <= '0;
        end
      end
    end
endmodule
