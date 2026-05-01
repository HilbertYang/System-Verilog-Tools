module uart_controller (
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

  // TODO: Instantiate uart_baud_gen, uart_tx, and uart_rx.

endmodule
