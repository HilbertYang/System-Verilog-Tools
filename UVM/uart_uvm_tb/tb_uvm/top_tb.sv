timeunit 1ns;
timeprecision 1ps;

module top_tb;

  import uvm_pkg::*;
  import uart_pkg::*;

  logic clk;

  localparam int CLKS_PER_BIT = 16;

  uart_if uart_vif(clk);

  uart_tx dut (
    .clk       (clk),
    .rst_n     (uart_vif.rst_n),
    .baud_tick (uart_vif.baud_tick),
    .tx_valid  (uart_vif.tx_valid),
    .tx_ready  (uart_vif.tx_ready),
    .tx_data   (uart_vif.tx_data),
    .tx        (uart_vif.tx)
  );

  initial begin
    $dumpfile("uart_tx_uvm.vcd");
    $dumpvars(0, top_tb);
  end

  initial begin
    clk = 1'b0;
    forever #5 clk = ~clk;
  end

  initial begin
    uart_vif.rst_n     = 1'b0;
    uart_vif.baud_tick = 1'b0;

    repeat (5) @(posedge clk);
    uart_vif.rst_n = 1'b1;
  end

  initial begin
    uart_vif.baud_tick = 1'b0;
    wait (uart_vif.rst_n);

    forever begin
      repeat (CLKS_PER_BIT - 1) @(negedge clk);
      uart_vif.baud_tick = 1'b1;
      @(negedge clk);
      uart_vif.baud_tick = 1'b0;
    end
  end

  initial begin
    uvm_config_db #(virtual uart_if)::set(null, "*", "vif", uart_vif);
    run_test("uart_tx_basic_test");
  end

endmodule
