module iterative_multiplier(
  input logic clk,
  input logic rst_n,
  input logic start,
  input logic [7:0] a,
  input logic [7:0] b,

  output logic busy,
  output logic done,
  output logic [15:0] product);

  logic [7:0][15:0] partial_product;
  logic [7:0] a_buff, b_buff;
  logic [3:0] cnt;
  logic [15:0] ans,previous_result;

  always_comb begin
      product = done? ans :previous_result;
  end
  always_ff@(posedge clk)begin
    if(!rst_n)begin
      cnt <= '0;
      previous_result <= '0;
      partial_product <= '0;
      busy <= '0;
      done <= '0;
      ans <= '0;
    end else begin
        done <= '0;
      if(done)begin
        previous_result <= ans;
      end
      if(start && ! busy)begin
        ans <= '0;
        busy <= 1'b1;
        a_buff <= a;
        b_buff <= b;
        partial_product[0] <= (b[0]) ? a : 0;
        cnt <= 1'b1;
      end else if(busy) begin
        if(cnt <= 7)begin
          partial_product[cnt] <= b_buff[cnt] ? (a_buff << cnt) : 0;
        end
        if(cnt == 8)begin
          done <= 1'b1;
          busy <= '0;
        end  
        ans <= ans + partial_product[cnt-1];
        cnt <= cnt + 1'b1;
      end
    end
  end
  endmodule
