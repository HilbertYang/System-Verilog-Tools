module stream_packer(
  input logic clk,
  input logic rst_n,

  input logic [7:0] in_data,
  input logic       in_valid,
  output logic       in_ready,

  output logic [31:0] out_data,
  output logic        out_valid,
  input logic         out_ready
  );
  logic [1:0] cnt;
  logic [4:0] index;
  assign index = {3'b0,cnt} << 3;
  assign in_ready = out_ready ||
                    !(out_valid);//It's a buffer!
 

  always_ff@(posedge clk)begin
    if(!rst_n)begin
      out_data <= '0;
      out_valid <= '0;
      cnt <= '0;
    end else begin
      if(in_valid && in_ready)begin
        cnt <= cnt + 1'b1;
        if(cnt == 2'd3)begin
          out_valid <= 1'b1;
        end
        out_data[index +: 8] <= in_data;
      end

      if(out_valid && out_ready) begin
        out_valid <= '0;
      end


    end
  end

  endmodule
