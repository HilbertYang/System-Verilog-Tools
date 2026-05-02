timeunit 1ns;
timeprecision 1ps;

module tb_uart_controller;

  logic       clk;
  logic       rst_n;
  logic       tx_valid;
  logic       tx_ready;
  logic [7:0] tx_data;
  logic       tx;
  logic       rx;
  logic       rx_valid;
  logic [7:0] rx_data;

  localparam int CLK_FREQ   = 1600;
  localparam int BAUD_RATE  = 10;
  localparam int OVERSAMPLE = 16;

  int unsigned error_count;

  assign rx = tx;

  uart_controller #(
    .CLK_FREQ   (CLK_FREQ),
    .BAUD_RATE  (BAUD_RATE),
    .OVERSAMPLE (OVERSAMPLE)
  ) dut (
    .clk      (clk),
    .rst_n    (rst_n),
    .tx_valid (tx_valid),
    .tx_ready (tx_ready),
    .tx_data  (tx_data),
    .tx       (tx),
    .rx       (rx),
    .rx_valid (rx_valid),
    .rx_data  (rx_data)
  );

  initial begin
    $dumpfile("tb_uart_controller.vcd");
    $dumpvars(0, tb_uart_controller);
  end

  initial begin
    clk = 1'b0;
    forever #5 clk = ~clk;
  end

  task automatic send_and_expect(input logic [7:0] data);
    wait (tx_ready);

    @(negedge clk);
    tx_data  = data;
    tx_valid = 1'b1;

    @(negedge clk);
    tx_valid = 1'b0;

    wait (rx_valid);

    if (rx_data !== data) begin
      $error("Loopback mismatch: expected=0x%02h actual=0x%02h time=%0t", data, rx_data, $time);
      error_count++;
    end

    @(posedge clk);
  endtask

  initial begin
    rst_n       = 1'b0;
    tx_valid    = 1'b0;
    tx_data     = '0;
    error_count = 0;

    repeat (3) @(posedge clk);
    rst_n = 1'b1;
    repeat (5) @(posedge clk);

    send_and_expect(8'h55);
    send_and_expect(8'hA5);
    send_and_expect(8'h00);
    send_and_expect(8'hFF);
    send_and_expect(8'h3C);

    if (error_count == 0) begin
      $display("TB PASSED: uart_controller loopback");
    end else begin
      $fatal(1, "TB FAILED: uart_controller errors=%0d", error_count);
    end

    $finish;
  end

endmodule
