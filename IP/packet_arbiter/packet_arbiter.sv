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

  logic cnt,next,sel;
  typedef enum logic {START, RECEIVING} states;
  states state;


  always_ff@(posedge clk)begin
    if(!rst_n)begin
      state <= START;
      next <= '0;
      cnt <= '0;
    end else begin
      case(state)
        START:begin
          if(out_valid) begin
            if(out_ready && out_last)begin
              next <= !sel;
              state <= START;
            end else begin
              cnt <= sel;
              state <= RECEIVING;
            end
          end
        end//START END
        RECEIVING:begin
          if(!cnt)begin
            if(out_last && out_valid && out_ready)begin
              state <= START;
              next  <= !cnt;
            end
          end
          if(cnt)begin
            if(out_last && out_valid && out_ready)begin
              state <= START;
              next <= !cnt;
            end
          end
        end//RECEVE END

        default:begin
        end
      endcase
    end
  end

  always_comb begin
    sel = cnt;
    if(state == START) begin
      if(in_valid[next]) sel = next;
      else if(in_valid[!next]) sel = !next;
    end


    in_ready = 2'b00;
    out_data = in_data[sel];
    out_valid = in_valid[sel];
    out_last = in_last[sel];
    if((state == RECEIVING)||out_valid) in_ready[sel] = out_ready;

  end


  endmodule
