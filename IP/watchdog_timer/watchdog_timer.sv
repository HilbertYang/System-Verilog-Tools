module watchdog_timer(
  input logic clk,
  input logic rst_n,
  input logic enable,
  input logic kick,
  input logic [7:0] cfg_timeout,

  output logic active,
  output logic timeout_pulse,
  output logic expired);
  
  logic [7:0] cnt,N;
  logic first_time_flag;

  always_ff@(posedge clk)begin
    if(!rst_n)begin
      active <= '0;
      timeout_pulse <= '0;
      cnt <= '0;
      expired <= '0;
      first_time_flag <= 1'b1;
      N <= 8'b1;
    end else begin
      if(enable)begin
        if(kick||first_time_flag)begin
          if(cfg_timeout == 0) N <= 8'b1;
          else N <= cfg_timeout;
          cnt <= 8'b1;
          expired <= '0;
          active <= 1'b1;
          timeout_pulse <= '0; 
          first_time_flag <= 1'b0;
        end else if(!expired) begin
          if(cnt == N)begin
            active <= '0;
            expired <= 1'b1;
            timeout_pulse <= 1'b1;
          end else begin 
          cnt <= cnt + 8'b1;
          end
        end else if(expired) begin
          timeout_pulse <= '0;
        end
      end else begin
        active <= '0;
        timeout_pulse <= '0;
        cnt <= '0;
        expired <= '0;
        first_time_flag <= 1'b1;
      end
    end
  end
  endmodule
