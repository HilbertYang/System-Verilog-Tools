module rr_arbiter(
  input logic clk,
  input logic rst_n,
  input logic [3:0] req,
  input logic ready,
  output logic [3:0] grant
);

  logic [1:0] cnt;

  always_ff@(posedge clk)begin
    if(!rst_n)begin
      cnt   <= '0;
    end else begin
      if(ready) begin
        if(grant[3]) cnt <= 0;
        if(grant[0]) cnt <= 1;
        if(grant[1]) cnt <= 2;
        if(grant[2]) cnt <= 3;
      end
    end
  end
        

  always_comb begin
    grant = 4'b0000;
    case(cnt)
      2'd0: begin
        if      (req[0]) grant = 4'b0001;
        else if (req[1]) grant = 4'b0010;
        else if (req[2]) grant = 4'b0100;
        else if (req[3]) grant = 4'b1000;
      end
      2'd1: begin
        if      (req[1]) grant = 4'b0010;
        else if (req[2]) grant = 4'b0100;
        else if (req[3]) grant = 4'b1000;
        else if (req[0]) grant = 4'b0001;
      end
      2'd2: begin
        if      (req[2]) grant = 4'b0100;
        else if (req[3]) grant = 4'b1000;
        else if (req[0]) grant = 4'b0001;
        else if (req[1]) grant = 4'b0010;
      end
      2'd3: begin
        if      (req[3]) grant = 4'b1000;
        else if (req[0]) grant = 4'b0001;
        else if (req[1]) grant = 4'b0010;
        else if (req[2]) grant = 4'b0100;
      end
    endcase
  end

  endmodule
