module uart_tx (
  input  logic       clk,
  input  logic       rst_n,

  input  logic       baud_tick,
  input  logic       tx_valid,

  output logic       tx_ready,
  input  logic [7:0] tx_data,
  output logic       tx
);

  // TODO: Implement UART TX state machine.

endmodule
