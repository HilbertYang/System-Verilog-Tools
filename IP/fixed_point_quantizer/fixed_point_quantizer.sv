module fixed_point_quantizer (
    input  logic               clk,
    input  logic               rst_n,
    input  logic               in_valid,
    input  logic signed [16:0] in_data,

    output logic               out_valid,
    output logic signed [7:0]  out_data,
    output logic               out_sat
);
  logic signed [9:0] run_int;
  logic [7:0] run_mod;
  logic run_sat_neg, run_sat_pos, run_sat;
  always_comb begin
    run_int = $signed({in_data[16], in_data[16:8]});
    run_mod = in_data[7:0];
    if(run_mod > 128)begin
      run_int = run_int + 1;
    end else if(run_mod == 128) begin
      if(run_int[0])begin
        run_int = run_int + 1;
      end else begin
        run_int = run_int;
      end
    end else begin
      run_int = run_int;
    end
    run_sat_pos = run_int > 127;
    run_sat_neg = run_int < -128;
    run_sat = run_sat_pos || run_sat_neg;
  end
  always_ff@(posedge clk)begin
    if(!rst_n)begin
      out_valid <= '0;
      out_data  <= '0;
      out_sat   <= '0;
    end else begin
      out_valid <= '0;
      if(in_valid)begin
        out_valid <= in_valid;
        out_data  <= run_sat?(run_sat_pos? 8'sh7F : 8'sh80 ) : run_int[7:0];
        out_sat   <= run_sat;
      end
    end
  end
endmodule
