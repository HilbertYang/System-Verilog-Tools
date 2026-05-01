module uart_baud_gen #(
  parameter int CLK_FREQ  = 50_000_000,
  parameter int BAUD_RATE = 115_200,
  parameter int OVERSAMPLE = 16,
  parameter int CLKS_PER_BIT = CLK_FREQ / BAUD_RATE,
  parameter int CLKS_PER_SAMPLE = CLK_FREQ / (BAUD_RATE * OVERSAMPLE)
)(
  input  logic clk,
  input  logic rst_n,
  output logic sample_tick,
  output logic baud_tick
);

  localparam int SAMPLE_CNT_WIDTH = (CLKS_PER_SAMPLE <= 1) ? 1 : $clog2(CLKS_PER_SAMPLE);
  localparam int SAMPLE_IDX_WIDTH = (OVERSAMPLE <= 1) ? 1 : $clog2(OVERSAMPLE);

  logic [SAMPLE_CNT_WIDTH-1:0] sample_cnt;
  logic [SAMPLE_IDX_WIDTH-1:0] sample_idx;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      sample_cnt  <= '0;
      sample_idx  <= '0;
      sample_tick <= 1'b0;
      baud_tick   <= 1'b0;
    end else begin
      sample_tick <= 1'b0;
      baud_tick   <= 1'b0;

      if (sample_cnt == CLKS_PER_SAMPLE - 1) begin
        sample_cnt  <= '0;
        sample_tick <= 1'b1;

        if (sample_idx == OVERSAMPLE - 1) begin
          sample_idx <= '0;
          baud_tick  <= 1'b1;
        end else begin
          sample_idx <= sample_idx + 1'b1;
        end
      end else begin
        sample_cnt <= sample_cnt + 1'b1;
      end
    end
  end

endmodule
