module uart_controller #(
  parameter int CLK_FREQ   = 50_000_000,
  parameter int BAUD_RATE  = 115_200,
  parameter int OVERSAMPLE = 16
)(
  input  logic       clk,
  input  logic       rst_n,

  input  logic       tx_valid,
  output logic       tx_ready,
  input  logic [7:0] tx_data,
  output logic       tx,

  input  logic       rx,
  output logic       rx_valid,
  output logic [7:0] rx_data
);

  logic sample_tick;
  logic baud_tick;

  uart_baud_gen #(
    .CLK_FREQ   (CLK_FREQ),
    .BAUD_RATE  (BAUD_RATE),
    .OVERSAMPLE (OVERSAMPLE)
  ) u_baud_gen (
    .clk         (clk),
    .rst_n       (rst_n),
    .sample_tick (sample_tick),
    .baud_tick   (baud_tick)
  );

  uart_tx u_tx (
    .clk       (clk),
    .rst_n     (rst_n),
    .baud_tick (baud_tick),
    .tx_valid  (tx_valid),
    .tx_ready  (tx_ready),
    .tx_data   (tx_data),
    .tx        (tx)
  );

  uart_rx #(
    .OVERSAMPLE (OVERSAMPLE)
  ) u_rx (
    .clk         (clk),
    .rst_n       (rst_n),
    .sample_tick (sample_tick),
    .rx          (rx),
    .rx_valid    (rx_valid),
    .rx_data     (rx_data)
  );

endmodule
