module uart_baud_gen #(
  parameter int CLK_FREQ  = 50_000_000,
  parameter int BAUD_RATE = 115_200,
  parameter int CLKS_PER_BIT = CLK_FREQ / BAUD_RATE
)(
  input  logic clk,
  input  logic rst_n,
  output logic baud_tick
);

  logic [$clog2(CLKS_PER_BIT)-1:0] cnt;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      cnt       <= '0;
      baud_tick <= 1'b0;
    end else begin
      if (cnt == CLKS_PER_BIT - 1) begin
        cnt       <= '0;
        baud_tick <= 1'b1;
      end else begin
        cnt <= cnt + 1'b1;
        baud_tick <= 1'b0;
      end
    end
  end

endmodule
