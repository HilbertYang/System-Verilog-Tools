module byte_stream_parser#(
    parameter pattern = 8'hEF
  )(
  input logic clk,
  input logic rst_n,
  input logic [7:0] d_in,
  output logic [15:0][7:0] d_out,
  output logic ready
  );

  logic [3:0] cnt;
  logic [1:0] cnt_sop;
  logic [7:0] parity;


  typedef enum logic [2:0] {SOP, DATA, CHECK} states;
  states state;
  
  
  always_ff@(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
      d_out <= '0;
      ready <= '0;
      cnt   <= '0;
      cnt_sop <= '0;
      state <= SOP;
    end else begin
      ready <= 1'b0;
      case(state)
        SOP:begin
          if(d_in == pattern)begin
            if(cnt_sop == 2) begin
              state <= DATA;
              cnt_sop <= '0;
              parity <= '0;
            end else begin  
            cnt_sop <= cnt_sop + 1'b1;
            end
          end else begin
            cnt_sop <= '0;
          end
        end
        DATA:begin
          d_out[cnt] <= d_in;
          cnt <= cnt + 1'b1;
          if(cnt == 15) state <= CHECK;
          parity[cnt >> 1] <= parity[cnt >> 1] ^ (^d_in);
        end
        CHECK:begin
          if(parity == d_in) ready <= 1;
          state <= SOP;
        end
      endcase        
    end
  end
endmodule

