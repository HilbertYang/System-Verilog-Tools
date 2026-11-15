module signed_sort4 (
    input  logic            clk,
    input  logic            rst_n,
    input  logic            in_valid,
    input  logic [3:0][7:0] in_data,

    output logic            out_valid,
    output logic [3:0][7:0] out_data,
    output logic [3:0][1:0] out_index
);
  logic [7:0] tmp;
  logic [1:0] tmp2;
  logic [3:0][7:0] tmp_data;
  logic [3:0][1:0] tmp_index;

  always_comb begin
    tmp_data = in_data;
    tmp_index = {2'd3, 2'd2, 2'd1, 2'd0};
    for(int i = 3; i > 0; i--)begin
      for(int j = 0; j < i; j++)begin
        if($signed(tmp_data[j]) > $signed(tmp_data[j+1]))begin
          tmp = tmp_data[j+1];
          tmp_data[j+1] = tmp_data[j];
          tmp_data[j]   = tmp;
          
          tmp2 = tmp_index[j+1];
          tmp_index[j+1] = tmp_index[j];
          tmp_index[j] = tmp2;
        end
      end
    end
  end

  always_ff@(posedge clk)begin
    if(!rst_n)begin
      out_valid <= '0;
      out_data  <= '0;
      out_index <= '0;
    end else begin
      if(in_valid)begin
        out_valid <= 1'b1;
        out_data  <= tmp_data;
        out_index <= tmp_index;
      end else begin
        out_valid <= '0;
      end
    end
  end
endmodule
