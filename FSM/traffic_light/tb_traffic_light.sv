`timescale 1ns/1ps

module tb_traffic_light;

    localparam int GREEN_TIME  = 4;
    localparam int YELLOW_TIME = 2;
    localparam int CLK_PERIOD  = 10;
    localparam int CYCLE       = GREEN_TIME * 2 + YELLOW_TIME * 2;

    localparam logic [1:0] RED    = 2'b00;
    localparam logic [1:0] YELLOW = 2'b01;
    localparam logic [1:0] GREEN  = 2'b10;

    logic       clk, rst_n;
    logic [1:0] ns_light, ew_light;

    traffic_light #(.GREEN_TIME(GREEN_TIME), .YELLOW_TIME(YELLOW_TIME)) dut (.*);

    initial clk = 0;
    always #(CLK_PERIOD/2) clk = ~clk;

    int pass_count, fail_count;

    task check(
        input logic [1:0] exp_ns,
        input logic [1:0] exp_ew,
        input string      label
    );
        if (ns_light === exp_ns && ew_light === exp_ew) begin
            $display("  PASS  [%s] ns=%02b ew=%02b", label, ns_light, ew_light);
            pass_count++;
        end else begin
            $display("  FAIL  [%s] ns=%02b ew=%02b  (expected ns=%02b ew=%02b)",
                     label, ns_light, ew_light, exp_ns, exp_ew);
            fail_count++;
        end
    endtask

    // Advance one cycle and check
    task tick(
        input logic [1:0] exp_ns,
        input logic [1:0] exp_ew,
        input string      label
    );
        @(posedge clk); #1;
        check(exp_ns, exp_ew, label);
    endtask

    initial begin
        pass_count = 0; fail_count = 0;
        $display("=== Traffic Light FSM Testbench (G=%0d Y=%0d) ===", GREEN_TIME, YELLOW_TIME);

        // reset
        rst_n = 0; @(posedge clk); #1;
        rst_n = 1;

        // ---- 1. Check reset state
        $display("\n[1] Reset state");
        check(GREEN, RED, "rst: ns=Green ew=Red");

        // ---- 2. Full first cycle: NS_GREEN phase
        $display("\n[2] NS_GREEN phase (%0d cycles)", GREEN_TIME);
        // cycle 1 already checked above; check remaining GREEN_TIME-1 cycles
        repeat(GREEN_TIME - 1) tick(GREEN, RED, "ns=Green ew=Red");

        // ---- 3. NS_YELLOW phase
        $display("\n[3] NS_YELLOW phase (%0d cycles)", YELLOW_TIME);
        repeat(YELLOW_TIME) tick(YELLOW, RED, "ns=Yellow ew=Red");

        // ---- 4. EW_GREEN phase
        $display("\n[4] EW_GREEN phase (%0d cycles)", GREEN_TIME);
        repeat(GREEN_TIME) tick(RED, GREEN, "ns=Red ew=Green");

        // ---- 5. EW_YELLOW phase
        $display("\n[5] EW_YELLOW phase (%0d cycles)", YELLOW_TIME);
        repeat(YELLOW_TIME) tick(RED, YELLOW, "ns=Red ew=Yellow");

        // ---- 6. Verify wrap back to NS_GREEN
        $display("\n[6] Wrap back to NS_GREEN");
        tick(GREEN, RED, "ns=Green ew=Red (wrap)");

        // ---- 7. Two never overlap: ns and ew are never both non-red
        $display("\n[7] NS and EW never both non-red (run 3 full cycles)");
        @(posedge clk); #1; // finish current cycle cleanly
        repeat(CYCLE * 3) begin
            @(posedge clk); #1;
            if (ns_light != RED && ew_light != RED) begin
                $display("  FAIL  Conflict: ns=%02b ew=%02b", ns_light, ew_light);
                fail_count++;
            end else begin
                pass_count++;
            end
        end
        $display("  (no conflicts in %0d cycles)", CYCLE * 3);

        // ---- 8. Reset during operation returns to NS_GREEN
        $display("\n[8] Reset during EW_GREEN returns to NS_GREEN");
        // advance into EW_GREEN
        repeat(GREEN_TIME + YELLOW_TIME + 1) @(posedge clk);
        rst_n = 0; @(posedge clk); #1;
        rst_n = 1;
        check(GREEN, RED, "after mid-run reset");

        $display("\n==========================================");
        $display("Result: %0d passed, %0d failed", pass_count, fail_count);
        if (fail_count == 0)
            $display("ALL TESTS PASSED");
        else
            $display("SOME TESTS FAILED");
        $finish;
    end

endmodule
