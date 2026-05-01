`timescale 1ns/1ps

module tb_vending_machine;

    localparam CLK_PERIOD = 10;

    logic clk, rst_n, nickel, dime, dispense, change;

    vending_machine dut (.*);

    initial clk = 0;
    always #(CLK_PERIOD/2) clk = ~clk;

    int pass_count, fail_count;

    task do_reset();
        rst_n = 0; nickel = 0; dime = 0;
        @(posedge clk); #1;
        rst_n = 1;
        @(posedge clk); #1;
    endtask

    // Insert one coin and capture outputs one cycle later
    task insert(input logic n, input logic d);
        nickel = n; dime = d;
        @(posedge clk); #1;
        nickel = 0; dime = 0;
    endtask

    task idle();
        nickel = 0; dime = 0;
        @(posedge clk); #1;
    endtask

    task check(
        input logic exp_dispense,
        input logic exp_change,
        input string label
    );
        if (dispense === exp_dispense && change === exp_change) begin
            $display("  PASS  [%s] dispense=%0b change=%0b", label, dispense, change);
            pass_count++;
        end else begin
            $display("  FAIL  [%s] dispense=%0b change=%0b  (expected dispense=%0b change=%0b)",
                     label, dispense, change, exp_dispense, exp_change);
            fail_count++;
        end
    endtask

    initial begin
        pass_count = 0; fail_count = 0;
        $display("=== Vending Machine FSM Testbench ===");

        // ---- 1. nickel + nickel + nickel → 15¢, exact
        $display("\n[1] 5+5+5 = 15c (exact, no change)");
        do_reset();
        insert(1,0); check(0, 0, "after 5c");
        insert(1,0); check(0, 0, "after 10c");
        insert(1,0); check(1, 0, "after 15c → dispense");
        idle();      check(0, 0, "back to S0");

        // ---- 2. dime + nickel → 15¢, exact
        $display("\n[2] 10+5 = 15c (exact, no change)");
        do_reset();
        insert(0,1); check(0, 0, "after 10c");
        insert(1,0); check(1, 0, "after 15c → dispense");
        idle();      check(0, 0, "back to S0");

        // ---- 3. nickel + dime → 15¢, exact
        $display("\n[3] 5+10 = 15c (exact, no change)");
        do_reset();
        insert(1,0); check(0, 0, "after 5c");
        insert(0,1); check(1, 0, "after 15c → dispense");
        idle();      check(0, 0, "back to S0");

        // ---- 4. dime + dime → 20¢, return change
        $display("\n[4] 10+10 = 20c (overpaid, change=1)");
        do_reset();
        insert(0,1); check(0, 0, "after 10c");
        insert(0,1); check(1, 1, "after 20c → dispense+change");
        idle();      check(0, 0, "back to S0");

        // ---- 5. nickel + nickel + dime → 20¢, return change
        $display("\n[5] 5+5+10 = 20c (overpaid, change=1)");
        do_reset();
        insert(1,0); check(0, 0, "after 5c");
        insert(1,0); check(0, 0, "after 10c");
        insert(0,1); check(1, 1, "after 20c → dispense+change");
        idle();      check(0, 0, "back to S0");

        // ---- 6. No coin inserted: stay idle
        $display("\n[6] No coins inserted");
        do_reset();
        repeat(4) begin
            idle();
            check(0, 0, "idle");
        end

        // ---- 7. Reset mid-transaction
        $display("\n[7] Reset mid-transaction");
        do_reset();
        insert(1,0); check(0, 0, "after 5c");
        // reset before inserting the last coin
        rst_n = 0; @(posedge clk); #1; rst_n = 1;
        insert(0,1); check(0, 0, "dime after reset → no dispense");
        idle();      check(0, 0, "stays idle");

        // ---- 8. Back-to-back transactions (idle one cycle between purchases)
        $display("\n[8] Back-to-back transactions");
        do_reset();
        // first purchase: 5+10 → S15
        insert(1,0);
        insert(0,1); check(1, 0, "tx1 dispense");
        // idle one cycle so S15 → S0 without eating a coin
        idle();      check(0, 0, "back to S0");
        // second purchase: 10+10 → S20
        insert(0,1); check(0, 0, "tx2 after 10c");
        insert(0,1); check(1, 1, "tx2 dispense+change");
        idle();      check(0, 0, "back to S0");

        $display("\n==========================================");
        $display("Result: %0d passed, %0d failed", pass_count, fail_count);
        if (fail_count == 0)
            $display("ALL TESTS PASSED");
        else
            $display("SOME TESTS FAILED");
        $finish;
    end

endmodule
