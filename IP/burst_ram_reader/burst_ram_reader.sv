module burst_ram_reader (
    input  logic       clk,
    input  logic       rst_n,

    input  logic       wr_en,
    input  logic [3:0] wr_addr,
    input  logic [7:0] wr_data,

    input  logic       req_valid,
    output logic       req_ready,
    input  logic [3:0] req_addr,
    input  logic [4:0] req_len,

    output logic [7:0] out_data,
    output logic       out_valid,
    output logic       out_last,
    input  logic       out_ready
);
  logic [15:0][7:0] ram;
  logic req_hs, out_hs;
  assign req_hs = req_valid && req_ready;
  assign out_hs = out_valid && out_ready;
  assign req_ready = !out_valid;
  logic [4:0] run_cnt, run_len;
  logic [3:0] run_addr;
  logic [5:0] run_result_addr;
  logic [1:0] UNCONN;
  assign UNCONN = run_result_addr[5:4];
  assign run_result_addr = {1'b0, run_cnt} + {1'b0, 1'b0, run_addr};
  always_ff@(posedge clk)begin
    if(!rst_n)begin
      out_data  <= '0;
      out_valid <= '0;
      out_last  <= '0;
      run_cnt   <= '0;
      run_len   <= '0;
      run_addr  <= '0;
    end else begin
      if(wr_en)begin
        ram[wr_addr] <= wr_data; 
      end
      if(req_hs)begin
        run_cnt <= 5'd1;
        run_len <= req_len;
        run_addr <= req_addr;
        out_data <= ram[req_addr];
        out_valid <= 1'b1;
        if(req_len == 1)
          out_last <= 1'b1;
      end else if(out_hs)begin
        if(run_cnt < run_len)begin
          out_data <= ram[run_result_addr[3:0]];
          run_cnt  <= run_cnt + 1'b1;
          if(run_cnt == run_len - 1) 
            out_last <= 1'b1;
        end else if(run_cnt == run_len)begin
          out_valid <= '0;
          out_last  <= '0;
        end
      end
    end
  end
endmodule 
