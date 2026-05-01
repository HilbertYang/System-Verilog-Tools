timeunit 1ns;
timeprecision 1ps;

module tb_uart_tx;

  logic       clk;
  logic       rst_n;
  logic       baud_tick;
  logic       tx_valid;
  logic       tx_ready;
  logic [7:0] tx_data;
  logic       tx;

  int unsigned error_count;

  uart_tx dut (
    .clk       (clk),
    .rst_n     (rst_n),
    .baud_tick (baud_tick),
    .tx_valid  (tx_valid),
    .tx_ready  (tx_ready),
    .tx_data   (tx_data),
    .tx        (tx)
  );

  initial begin
    $dumpfile("tb_uart_tx.vcd");
    $dumpvars(0, tb_uart_tx);
  end

  initial begin
    clk = 1'b0;
    forever #5 clk = ~clk;
  end

  task automatic pulse_tick();
    @(negedge clk);
    baud_tick = 1'b1;
    @(negedge clk);
    baud_tick = 1'b0;
  endtask

  task automatic check_bit(input logic actual, input logic expected, input string label);
    if (actual !== expected) begin
      $error("%s mismatch: expected=%0b actual=%0b time=%0t", label, expected, actual, $time);
      error_count++;
    end
  endtask

  task automatic send_and_check(input logic [7:0] data);
    @(negedge clk);
    tx_data  = data;
    tx_valid = 1'b1;

    @(negedge clk);
    tx_valid = 1'b0;

    check_bit(tx, 1'b0, "start bit");
    pulse_tick();

    for (int i = 0; i < 8; i++) begin
      check_bit(tx, data[i], $sformatf("data bit %0d", i));
      pulse_tick();
    end

    check_bit(tx, 1'b1, "stop bit");
    pulse_tick();

    check_bit(tx, 1'b1, "idle bit");
    if (!tx_ready) begin
      $error("tx_ready should be high after stop bit, time=%0t", $time);
      error_count++;
    end
  endtask

  initial begin
    rst_n       = 1'b0;
    baud_tick   = 1'b0;
    tx_valid    = 1'b0;
    tx_data     = '0;
    error_count = 0;

    repeat (3) @(posedge clk);
    rst_n = 1'b1;
    repeat (2) @(posedge clk);

    if (!tx_ready || tx !== 1'b1) begin
      $error("TX should be idle after reset");
      error_count++;
    end

    send_and_check(8'h55);
    send_and_check(8'hA5);
    send_and_check(8'h00);
    send_and_check(8'hFF);

    if (error_count == 0) begin
      $display("TB PASSED: uart_tx");
    end else begin
      $fatal(1, "TB FAILED: uart_tx errors=%0d", error_count);
    end

    $finish;
  end

endmodule
