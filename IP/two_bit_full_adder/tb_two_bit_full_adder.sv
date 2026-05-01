`timescale 1ns/1ps

module tb_two_bit_full_adder;

    logic [1:0] a, b;
    logic       cin;
    logic [1:0] sum;
    logic       cout;

    two_bit_full_adder dut (.*);

    int pass_count, fail_count;

    task check(input logic [1:0] ta, tb, input logic tc);
        logic [2:0] expected;
        a = ta; b = tb; cin = tc;
        #1;
        expected = {1'b0, ta} + {1'b0, tb} + {2'b0, tc};
        if ({cout, sum} === expected) begin
            $display("  PASS  a=%02b b=%02b cin=%0b → sum=%02b cout=%0b",
                     ta, tb, tc, sum, cout);
            pass_count++;
        end else begin
            $display("  FAIL  a=%02b b=%02b cin=%0b → sum=%02b cout=%0b  (expected sum=%02b cout=%0b)",
                     ta, tb, tc, sum, cout, expected[1:0], expected[2]);
            fail_count++;
        end
    endtask

    initial begin
        pass_count = 0; fail_count = 0;
        $display("=== 2-bit Full Adder Testbench (exhaustive 2^5=32) ===");

        // Exhaustive: all 32 input combinations
        for (int i = 0; i < 32; i++)
            check(i[4:3], i[2:1], i[0]);

        $display("--------------------------------------------------");
        $display("Result: %0d passed, %0d failed", pass_count, fail_count);
        if (fail_count == 0) $display("ALL TESTS PASSED");
        else                 $display("SOME TESTS FAILED");
        $finish;
    end

endmodule
