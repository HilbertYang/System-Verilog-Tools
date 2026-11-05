`timescale 1ns/1ps

module tb_moving_sum4_continuous;
    logic clk = 1'b0;
    logic rst_n = 1'b0;
    logic [7:0] in_data = 8'd0;
    logic in_valid = 1'b0;
    wire [9:0] out_sum;
    wire out_valid;

    logic [9:0] expected_sum = 10'd0;
    logic expected_valid = 1'b0;
    integer checks_failed = 0;
    integer accepted_samples = 0;
    string wave_file;

    moving_sum4 dut (.*);

    always #5 clk = ~clk;

    task automatic drive_cycle(
        input logic valid_value,
        input logic [7:0] data_value,
        input logic valid_expected,
        input logic [9:0] sum_expected
    );
        // Change inputs on falling edges and hold them through the rising edge.
        @(negedge clk);
        in_valid = valid_value;
        in_data = data_value;

        @(posedge clk);
        $display("BEFORE t=%0.3f ns valid=%0b data=%0d out=%0d out_valid=%0b",
                 $realtime, in_valid, in_data, out_sum, out_valid);

        // Wait 1 ps for NBA register updates and combinational reevaluation.
        #0.001;
        if (valid_value)
            accepted_samples = accepted_samples + 1;
        expected_valid = valid_expected;
        expected_sum = sum_expected;

        $display("AFTER  t=%0.3f ns valid=%0b data=%0d out=%0d out_valid=%0b expected=%0d/%0b accepted=%0d",
                 $realtime, in_valid, in_data, out_sum, out_valid,
                 expected_sum, expected_valid, accepted_samples);

        if (out_sum !== expected_sum || out_valid !== expected_valid) begin
            checks_failed = checks_failed + 1;
            $display("MISMATCH: observed sum/valid=%0d/%0b, expected=%0d/%0b",
                     out_sum, out_valid, expected_sum, expected_valid);
        end
    endtask

    initial begin
        if (!$value$plusargs("wave_file=%s", wave_file))
            wave_file = "moving_sum4_continuous.vcd";
        $dumpfile(wave_file);
        $dumpvars(0, tb_moving_sum4_continuous);

        repeat (2) @(posedge clk);
        #1;
        rst_n = 1'b1;

        // in_valid stays high from 20 ns through 70 ns: no gaps between samples.
        drive_cycle(1'b1, 8'd10, 1'b0, 10'd0);
        drive_cycle(1'b1, 8'd20, 1'b0, 10'd0);
        drive_cycle(1'b1, 8'd30, 1'b0, 10'd0);
        drive_cycle(1'b1, 8'd40, 1'b1, 10'd100);
        drive_cycle(1'b1, 8'd50, 1'b1, 10'd140);
        drive_cycle(1'b0, 8'd50, 1'b0, 10'd140);

        #5;
        $display("SUMMARY: %0d output checks failed.", checks_failed);
        if (checks_failed != 0)
            $fatal(1, "Current RTL does not match the problem's post-edge outputs; inspect the VCD.");
        $finish;
    end
endmodule
