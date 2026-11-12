module pwm_generator (
    input  logic       clk,
    input  logic       rst_n,

    input  logic       cfg_valid,
    input  logic [7:0] cfg_period,
    input  logic [7:0] cfg_duty,

    output logic       pwm,
    output logic       frame_start
);
  logic [7:0]   period, duty, period_next, duty_next, cnt;
  always_ff@(posedge clk)begin
    if(!rst_n)begin
      period <= 1'b1;
      duty   <= '0;
      cnt    <= '0;
      pwm    <= '0;
      period_next <= 1'b1;
      duty_next <= '0;
      frame_start <= '0;
    end else begin
      frame_start <= '0;
      cnt <= cnt + 1'b1;
      
      if(cfg_valid)begin
        period_next <= cfg_period ? cfg_period : 1'b1;
        duty_next   <= (cfg_duty <= cfg_period) ? cfg_duty : (cfg_period ? cfg_period : 1'b1);
      end

      if(cnt == duty - 1) begin
        pwm <= '0;
      end

      if(cnt == period - 1)begin
        cnt <= '0;
        frame_start <= 1'b1;
        period  <= cfg_valid ? (cfg_period ? cfg_period : 1'b1) : period_next;
        duty    <= cfg_valid ? ((cfg_duty <= cfg_period) ? cfg_duty : (cfg_period ? cfg_period : 1'b1)) : duty_next;
        pwm     <= cfg_valid ? |cfg_duty : |duty_next;
      end 
    end
  end
endmodule
