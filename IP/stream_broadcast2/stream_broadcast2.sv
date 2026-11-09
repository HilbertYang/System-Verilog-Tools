module stream_broadcast2 (
    input  logic            clk,
    input  logic            rst_n,

    input  logic [7:0]      in_data,
    input  logic            in_valid,
    output logic            in_ready,

    output logic [1:0][7:0] out_data,
    output logic [1:0]      out_valid,
    input  logic [1:0]      out_ready
);

  logic hs_in;
  logic [1:0] hs_out;

  assign in_ready = &(~out_valid | hs_out);
  assign hs_in = in_valid && in_ready;
  assign  hs_out    = out_valid & out_ready;   

  always_ff@(posedge clk)begin
    if (!rst_n)begin
      out_data    <= '0;
      out_valid   <= '0;
    end else begin
      
      if(hs_in)begin
        for(int i = 0; i<2; i++)begin
          out_data[i] <= in_data;
          out_valid[i] <= 1'b1;
        end
      end else begin
        for(int i = 0; i <2; i++)begin
          if(hs_out[i])begin
            out_valid[i] <= '0;
          end
        end
      end
    end
  end
endmodule
