`timescale 1ns/1ps

module tb_two_bit_full_adder;

    logic [1:0] a, b;
    logic       cin;
    logic [1:0] sum;
    logic       cout;

    two_bit_full_adder dut (.*);

    // Reference model
    logic [2:0] expected;
    always_comb expected = {1'b0, a} + {1'b0, b} + {2'b0, cin};

    int pass_count, fail_count;

    task automatic check(
        input logic [1:0] ta, tb,
        input logic       tcin
    );
        a   = ta;
        b   = tb;
        cin = tcin;
        #1;
        if ({cout, sum} === expected) begin
            $display("PASS  a=%0b b=%0b cin=%0b → sum=%0b cout=%0b",
                     ta, tb, tcin, sum, cout);
            pass_count++;
        end else begin
            $display("FAIL  a=%0b b=%0b cin=%0b → sum=%0b cout=%0b  (expected sum=%0b cout=%0b)",
                     ta, tb, tcin, sum, cout, expected[1:0], expected[2]);
            fail_count++;
        end
    endtask

    initial begin
        pass_count = 0;
        fail_count = 0;
        $display("=== 2-bit Full Adder Testbench ===");

        // Exhaustive: all 2^5 = 32 combinations
        for (int i = 0; i < 32; i++) begin
            check(i[4:3], i[2:1], i[0]);
        end

        $display("----------------------------------");
        $display("Result: %0d passed, %0d failed", pass_count, fail_count);
        if (fail_count == 0)
            $display("ALL TESTS PASSED");
        else
            $display("SOME TESTS FAILED");
        $finish;
    end

endmodule
