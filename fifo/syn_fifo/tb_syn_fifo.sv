`timescale 1ns/1ps

module tb_syn_fifo;

    // ------------------------------------------------------------------ params
    localparam int DATA_WIDTH = 8;
    localparam int DEPTH      = 8;
    localparam int CLK_PERIOD = 10;

    // ------------------------------------------------------------------ signals
    logic                  clk, rst_n;
    logic                  wr_en, rd_en;
    logic [DATA_WIDTH-1:0] wr_data;
    logic [DATA_WIDTH-1:0] rd_data;
    logic                  full, empty;

    // ------------------------------------------------------------------ DUT
    syn_fifo #(.DATA_WIDTH(DATA_WIDTH), .DEPTH(DEPTH)) dut (.*);

    // ------------------------------------------------------------------ clock
    initial clk = 0;
    always #(CLK_PERIOD/2) clk = ~clk;

    // ------------------------------------------------------------------ helpers
    int pass_count, fail_count;

    task reset();
        rst_n = 0; wr_en = 0; rd_en = 0; wr_data = '0;
        @(posedge clk); #1;
        rst_n = 1;
        @(posedge clk); #1;
    endtask

    task write(input logic [DATA_WIDTH-1:0] data);
        wr_en = 1; wr_data = data; rd_en = 0;
        @(posedge clk); #1;
        wr_en = 0;
    endtask

    task read(output logic [DATA_WIDTH-1:0] data);
        rd_en = 1; wr_en = 0;
        @(posedge clk); #1;
        data  = rd_data;
        rd_en = 0;
    endtask

    task check_flag(string name, logic actual, logic expected);
        if (actual === expected) begin
            $display("  PASS  %-10s = %0b", name, actual);
            pass_count++;
        end else begin
            $display("  FAIL  %-10s = %0b  (expected %0b)", name, actual, expected);
            fail_count++;
        end
    endtask

    task check_data(logic [DATA_WIDTH-1:0] actual, expected);
        if (actual === expected) begin
            $display("  PASS  rd_data = 0x%02h", actual);
            pass_count++;
        end else begin
            $display("  FAIL  rd_data = 0x%02h  (expected 0x%02h)", actual, expected);
            fail_count++;
        end
    endtask

    // ------------------------------------------------------------------ tests
    logic [DATA_WIDTH-1:0] rdata;

    initial begin
        pass_count = 0; fail_count = 0;
        $display("=== Synchronous FIFO Testbench (DEPTH=%0d) ===", DEPTH);

        // ---- 1. Reset state
        $display("\n[1] After reset");
        reset();
        check_flag("empty", empty, 1'b1);
        check_flag("full",  full,  1'b0);

        // ---- 2. Fill FIFO
        $display("\n[2] Fill FIFO with 0x00..0x%02h", DEPTH-1);
        for (int i = 0; i < DEPTH; i++)
            write(DATA_WIDTH'(i));
        check_flag("full",  full,  1'b1);
        check_flag("empty", empty, 1'b0);

        // ---- 3. Write-when-full should be ignored
        $display("\n[3] Write when full (should be ignored)");
        write(8'hFF);
        check_flag("full", full, 1'b1);

        // ---- 4. Drain FIFO, check FIFO order
        $display("\n[4] Drain FIFO, verify FIFO order");
        for (int i = 0; i < DEPTH; i++) begin
            read(rdata);
            check_data(rdata, DATA_WIDTH'(i));
        end
        check_flag("empty", empty, 1'b1);

        // ---- 5. Read-when-empty should be ignored
        $display("\n[5] Read when empty (rd_data should not change)");
        rd_en = 1; @(posedge clk); #1; rd_en = 0;
        check_flag("empty", empty, 1'b1);

        // ---- 6. Simultaneous read/write (occupancy stays the same)
        $display("\n[6] Simultaneous read and write");
        write(8'hAA);                        // push one item
        wr_en = 1; rd_en = 1; wr_data = 8'hBB;
        @(posedge clk); #1;
        wr_en = 0; rd_en = 0;
        check_data(rd_data, 8'hAA);          // should have read AA
        // one item (BB) still in FIFO
        check_flag("empty", empty, 1'b0);
        check_flag("full",  full,  1'b0);

        // ---- 7. Wrap-around: write/read across pointer wrap
        $display("\n[7] Pointer wrap-around");
        reset();
        // fill and drain 3/4 to move pointers near wrap boundary
        repeat(DEPTH*3/4) begin
            write($urandom_range(0, 255));
        end
        repeat(DEPTH*3/4) read(rdata);
        // now fill again to cross the wrap boundary
        for (int i = 0; i < DEPTH; i++)
            write(DATA_WIDTH'(8'hC0 + i));
        check_flag("full", full, 1'b1);
        for (int i = 0; i < DEPTH; i++) begin
            read(rdata);
            check_data(rdata, DATA_WIDTH'(8'hC0 + i));
        end
        check_flag("empty", empty, 1'b1);

        // ---- Summary
        $display("\n==========================================");
        $display("Result: %0d passed, %0d failed", pass_count, fail_count);
        if (fail_count == 0)
            $display("ALL TESTS PASSED");
        else
            $display("SOME TESTS FAILED");
        $finish;
    end

endmodule
