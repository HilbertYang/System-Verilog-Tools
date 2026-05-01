timeunit 1ns;
timeprecision 1ps;

module tb_uart_rx;

  logic       clk;
  logic       rst_n;
  logic       sample_tick;
  logic       rx;
  logic       rx_valid;
  logic [7:0] rx_data;

  localparam int OVERSAMPLE = 16;

  int unsigned error_count;

  uart_rx #(
    .OVERSAMPLE(OVERSAMPLE)
  ) dut (
    .clk         (clk),
    .rst_n       (rst_n),
    .sample_tick (sample_tick),
    .rx          (rx),
    .rx_valid    (rx_valid),
    .rx_data     (rx_data)
  );

  initial begin
    $dumpfile("tb_uart_rx.vcd");
    $dumpvars(0, tb_uart_rx);
  end

  initial begin
    clk = 1'b0;
    forever #5 clk = ~clk;
  end

  task automatic pulse_tick();
    @(negedge clk);
    sample_tick = 1'b1;
    @(negedge clk);
    sample_tick = 1'b0;
  endtask

  task automatic drive_and_check(input logic [7:0] data);
    @(negedge clk);
    rx = 1'b0;
    repeat (OVERSAMPLE / 2) pulse_tick();

    for (int i = 0; i < 8; i++) begin
      rx = data[i];
      repeat (OVERSAMPLE) pulse_tick();
    end

    rx = 1'b1;
    repeat (OVERSAMPLE) pulse_tick();

    if (!rx_valid) begin
      $error("rx_valid should be high after stop bit, time=%0t", $time);
      error_count++;
    end

    if (rx_data !== data) begin
      $error("rx_data mismatch: expected=0x%02h actual=0x%02h time=%0t", data, rx_data, $time);
      error_count++;
    end

    @(posedge clk);
  endtask

  initial begin
    rst_n       = 1'b0;
    sample_tick = 1'b0;
    rx          = 1'b1;
    error_count = 0;

    repeat (3) @(posedge clk);
    rst_n = 1'b1;
    repeat (2) @(posedge clk);

    drive_and_check(8'h55);
    drive_and_check(8'hA5);
    drive_and_check(8'h00);
    drive_and_check(8'hFF);

    if (error_count == 0) begin
      $display("TB PASSED: uart_rx");
    end else begin
      $fatal(1, "TB FAILED: uart_rx errors=%0d", error_count);
    end

    $finish;
  end

endmodule
