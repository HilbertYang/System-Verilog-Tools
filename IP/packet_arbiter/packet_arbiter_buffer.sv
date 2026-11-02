module packet_arbiter(
  input logic clk,
  input logic rst_n,

  input logic [1:0][7:0] in_data,
  input logic [1:0]      in_valid,
  input logic [1:0]      in_last,
  output logic [1:0]      in_ready,

  output logic [7:0]  out_data,
  output logic        out_valid,
  output logic        out_last,
  input logic        out_ready);

  logic [1:0] in_hs;
  assign in_hs = in_valid & in_ready;
  assign in_ready[0] = (out_hs || !out_valid)&&!cnt&&(state == RECEIVING);
  assign in_ready[1] = (out_hs || !out_valid)&& cnt&&(state == RECEIVING);
  logic out_hs;
  assign out_hs = out_valid && out_ready;

  logic cnt,next;
  typedef enum logic {START, RECEIVING} states;
  states state;


  always@(posedge clk)begin
    if(!rst_n)begin
      out_data <= '0;
      out_valid <= '0;
      out_last <= '0;
      cnt <= '0;
      next <= '0;
      state <= START;
    end else begin
      case(state)
        START:begin
          if(out_hs)begin
            out_valid <= '0;
            out_last  <= '0;
          end
          if(!next)begin
            if(in_valid[0])begin
              cnt <= '0;
              state<=RECEIVING;
            end else if(in_valid[1])begin
              cnt <= 1'b1;
              state <= RECEIVING;
            end else begin
              state <= START;
            end
          end else begin
            if(in_valid[1])begin
              cnt <= 1'b1;
              state<=RECEIVING;
            end else if(in_valid[0])begin
              cnt <= '0;
              state <= RECEIVING;
            end else begin
              state <= START;
            end
          end

        end
        RECEIVING:begin
          if(out_hs)begin
            out_valid <= '0;
            out_last  <= '0;
          end
          if(!cnt)begin
            if(in_hs[0])begin
              out_data <= in_data[0];
              out_valid <= 1'b1;
            end
            if(in_last[0]&&in_hs[0])begin
              state <= START;
              out_last <= in_last[0];
              next <= !cnt;
            end
          end else begin
            if(in_hs[1])begin
              out_data <= in_data[1];
              out_valid <= 1'b1;
            end
            if(in_last[1]&&in_hs[1])begin
              state <= START;
              out_last <= in_last[1];
              next <= !cnt;
            end
          end
        end
        default:begin
        end
      endcase
    end
  end

  endmodule
