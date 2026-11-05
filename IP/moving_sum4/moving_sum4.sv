module moving_sum4(
  input logic clk,
  input logic rst_n,
  input logic [7:0] in_data,
  input logic in_valid,

  output logic [9:0] out_sum,
  output logic out_valid
  );

  logic [3:0][7:0] buff;
  logic [3:0] cnt;
  logic [9:0] psum;

  always_ff@(posedge clk)begin
    if(!rst_n)begin
      buff <= '0;
      cnt  <= '0;
      psum <= '0;
      out_valid <= '0;
    end else begin
      out_valid <= '0;
      if(in_valid)begin
        
        buff[0] <= buff[1];
        buff[1] <= buff[2];
        buff[2] <= buff[3];
        buff[3] <= in_data;
        psum    <= psum + in_data - buff[0];
        if(cnt < 4)   cnt <= cnt + 1'b1;
        if(cnt >= 3) out_valid <= 1'b1;
      end 
    end
  end

  always_comb begin
    out_sum = (cnt == 4) ? psum : '0;
  end
  endmodule
