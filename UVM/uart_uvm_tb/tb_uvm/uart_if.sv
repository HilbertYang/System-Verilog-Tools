interface uart_if(input logic clk);

  logic       rst_n;
  logic       baud_tick;
  logic       tx_valid;
  logic       tx_ready;
  logic [7:0] tx_data;
  logic       tx;

endinterface
