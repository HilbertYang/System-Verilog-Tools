module packet_crc8 (
    input  logic       clk,
    input  logic       rst_n,

    input  logic [7:0] in_data,
    input  logic       in_valid,
    input  logic       in_last,
    output logic       in_ready,

    output logic [7:0] out_crc,
    output logic       out_valid,
    input  logic       out_ready
);
  logic feedBack;
  logic [7:0] c, c_partial;
  logic in_hs, out_hs;
  assign in_hs = in_valid && in_ready;
  assign out_hs = out_valid && out_ready;
  assign in_ready = !out_valid || out_hs;
  
  always_comb begin
    c = c_partial;
    for(int i=7; i >=0 ; i--)begin
      feedBack = c[7] ^ in_data[i];
      c = c << 1;
      if(feedBack)begin
        c ^= 8'h07;
      end
    end
  end

  always_ff@(posedge clk)begin
    if(!rst_n) begin
      out_crc <= '0;
      out_valid <= '0;
      c_partial <= '0;
    end else begin
      if(in_hs)begin
        c_partial <= c;
        if(in_last)begin
          out_valid <= 1'b1;
          out_crc <= c;
          c_partial <= '0;
        end else if(out_hs) begin
          out_valid <= '0;
        end
      end else if(out_hs) begin
        out_valid <= '0;
      end
    end
  end
endmodule
