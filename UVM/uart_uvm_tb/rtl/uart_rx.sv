module uart_rx (
  input  logic       clk,
  input  logic       rst_n,

  input  logic       baud_tick,
  input  logic       rx,

  output logic       rx_valid,
  output logic [7:0] rx_data
);

  // TODO: Implement UART RX state machine.

endmodule
