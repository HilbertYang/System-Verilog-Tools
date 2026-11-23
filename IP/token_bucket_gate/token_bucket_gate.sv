module token_bucket_gate (
    input  logic       clk,
    input  logic       rst_n,

    input  logic       refill_valid,
    input  logic [3:0] refill_amount,
    output logic [3:0] token_count,

    input  logic       in_valid,
    output logic       in_ready,
    input  logic [7:0] in_data,
    input  logic [3:0] in_cost,

    output logic       out_valid,
    input  logic       out_ready,
    output logic [7:0] out_data
);
  logic out_hs;
  logic in_hs;
  logic [4:0] next_count;
  assign next_count = (!refill_valid) ? {1'b0, token_count} :
                      ((({1'b0, token_count} + {1'b0, refill_amount}) > 5'd15) ? 
                      5'd15 : 
                      ({1'b0, token_count} + {1'b0, refill_amount})); 
  assign in_ready = (((!out_valid)||out_hs)&&(((|in_cost)? in_cost : 4'b1)<=next_count[3:0]));
  assign out_hs = out_valid && out_ready;
  assign in_hs  = in_valid && in_ready;
  
  always_ff@(posedge clk)begin
    if(!rst_n)begin
      out_data    <= '0;
      out_valid   <= '0;
      token_count <= '0;
    end else begin
      if(refill_valid)begin
        token_count   <=  next_count[3:0];
      end
      if(in_hs)begin
        out_valid <= 1'b1;
        out_data  <= in_data;
        token_count <= next_count[3:0] -((|in_cost)? in_cost : 4'b1);
      end else if(out_hs) begin
        out_valid <= '0;
      end
    end
  end
endmodule
