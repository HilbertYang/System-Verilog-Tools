module pulse_cdc_handshake(
  input logic src_clk,
  input logic dst_clk,
  input logic rst_n,

  input logic src_pulse,
  output logic src_busy,
  output logic dst_pulse);
  
  logic req, ack, req_sync, ack_sync;
  
  synchronizer u_req_sync(
    .clk(dst_clk),
    .rst_n(rst_n),
    .sig_in(req),
    .sig_out(req_sync));

 synchronizer u_ack_sync(
    .clk(src_clk),
    .rst_n(rst_n),
    .sig_in(ack),
    .sig_out(ack_sync));

  always_comb begin
    src_busy = (req != ack_sync);
    dst_pulse = (req_sync != ack);
  end
  
  always_ff@(posedge src_clk or negedge rst_n)begin
    if(~rst_n) begin
      req <= '0;
    end else begin
    if(src_pulse && !src_busy) req <= ~req;
    end
  end

  always_ff@(posedge dst_clk or negedge rst_n)begin
    if(~rst_n) begin
      ack <= '0;
    end else begin
    if(req_sync != ack) ack <= ~ack;
    end
  end
  
endmodule

module synchronizer(
  input logic clk,
  input logic rst_n,
  input logic sig_in,
  output logic sig_out
  );
  logic sig_in_d;

  always_ff@(posedge clk or negedge rst_n)begin
    if(~rst_n)begin
      sig_in_d <= '0;
      sig_out <= '0;
    end else begin
      sig_in_d <= sig_in;
      sig_out  <= sig_in_d;
    end
  end
endmodule
