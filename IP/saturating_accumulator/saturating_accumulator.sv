module saturating_accumulator(
  input logic   clk,
  input logic   rst_n,
  input logic   clear,
  input logic   in_valid,
  input logic signed[7:0] in_data,

  output logic signed [7:0] acc,
  output logic  sat_pulse);
    
  logic signed [10:0] tmp_val;
  logic signed flag;

  always_comb begin
    tmp_val   = acc + in_data;
    sat_pulse = flag;
  end 

  always@(posedge clk) begin
    if(!rst_n)begin 
      acc <= '0;
      flag <= '0;
    end else begin
      if(clear) begin
        acc <= '0;
        flag <= '0;
      end else begin
        if(in_valid)begin
          if(tmp_val > 127)begin
            acc <= 127;
            flag<= 1'b1;
          end else if (tmp_val < -128) begin
            acc <= -128;
            flag <= 1'b1;
          end else begin
            acc <= acc + in_data;
            flag <= '0;
          end
        end else begin
          flag <= '0;
        end
      end
    end
  end
  endmodule
