module programmable_debouncer (
    input  logic       clk,
    input  logic       rst_n,
    input  logic       sig_in,
    input  logic [7:0] cfg_rise_samples,
    input  logic [7:0] cfg_fall_samples,

    output logic       level,
    output logic       rise_pulse,
    output logic       fall_pulse
);
  logic [7:0] cnt, rise_lock, fall_lock;
  always_ff@(posedge clk)begin
    if(!rst_n)begin
      level       <= '0;
      rise_pulse  <= '0;
      fall_pulse  <= '0;
      cnt         <= '0;
      rise_lock   <= 8'b1;
      fall_lock   <= 8'b1;
    end else begin
      rise_pulse  <= '0;
      fall_pulse  <= '0;
      if(level)begin
        if(!sig_in)begin 
          cnt <= cnt + 1'b1;
          if(!(|cnt))fall_lock     <= (|cfg_fall_samples) ? cfg_fall_samples : 8'b1; 
        end else begin
          cnt <= '0;
        end

        if(cnt == ((!(|cnt))?((|cfg_fall_samples) ? cfg_fall_samples - 8'b1: 8'b0):(fall_lock - 1'b1))&&(!sig_in))begin
          level         <= '0;
          rise_pulse    <= '0;
          fall_pulse    <= 1'b1;
          cnt           <= '0;
        end

      end else begin
        if(sig_in)begin
          cnt <= cnt + 1'b1;
          if(!(|cnt))rise_lock     <= (|cfg_rise_samples) ? cfg_rise_samples : 8'b1;
        end else begin
          cnt <= '0;
        end

        if(cnt == ((!(|cnt))?((|cfg_rise_samples) ? cfg_rise_samples - 8'b1 : 8'b0):(rise_lock - 1'b1))&&(sig_in))begin
          level         <= 1'b1;
          rise_pulse    <= 1'b1;
          fall_pulse    <= '0;
          cnt           <= '0;
        end

      end
    end
  end
endmodule
