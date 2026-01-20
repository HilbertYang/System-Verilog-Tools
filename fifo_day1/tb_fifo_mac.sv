module tb_fifo;

  // iverilog 兼容：避免 localparam int
  parameter WIDTH = 8;
  parameter DEPTH = 16;

  // iverilog 兼容：TB 里用 reg/wire 更稳
  reg  clk, rst_n;
  reg  wr_en, rd_en;
  reg  [WIDTH-1:0] wdata;
  wire [WIDTH-1:0] rdata;
  wire full, empty;
  wire [$clog2(DEPTH+1)-1:0] count;

  fifo_sync #(.WIDTH(WIDTH), .DEPTH(DEPTH)) dut (
    .clk(clk), .rst_n(rst_n),
    .wr_en(wr_en), .wdata(wdata), .full(full),
    .rd_en(rd_en), .rdata(rdata), .empty(empty),
    .count(count)
  );

  // clock
  initial clk = 0;
  always #5 clk = ~clk;

  // dump waveform for GTKWave
  initial begin
    $dumpfile("wave.vcd");
    $dumpvars(0, tb_fifo);
  end

  // ---------------- Golden model (no queue) ----------------
  // 用数组 + head/tail 模拟 queue，避免 iverilog queue 支持问题
  reg [WIDTH-1:0] golden_mem [0:10000];
  integer g_head, g_tail, g_size;

  // push
  task push;
    input [WIDTH-1:0] d;
    begin
      @(negedge clk);
      wr_en = 1;
      wdata = d;
      rd_en = 0;

      @(posedge clk);
      if (!full) begin
        golden_mem[g_tail] = d;
        g_tail = g_tail + 1;
        g_size = g_size + 1;
      end

      @(negedge clk);
      wr_en = 0;
    end
  endtask

  // pop
  task pop;
    reg [WIDTH-1:0] expect;
    begin
      @(negedge clk);
      rd_en = 1;
      wr_en = 0;

      @(posedge clk);
      #0; // 等一个 delta，让同步读 rdata 更稳
      if (!empty) begin
        expect = golden_mem[g_head];
        g_head = g_head + 1;
        g_size = g_size - 1;

        if (rdata !== expect) begin
          $display("[FAIL] time=%0t rdata=%0h expect=%0h", $time, rdata, expect);
          $fatal(1);
        end else begin
          $display("[PASS] time=%0t rdata=%0h", $time, rdata);
        end
      end

      @(negedge clk);
      rd_en = 0;
    end
  endtask

  integer i;
  integer k;

  // 主流程
  initial begin
    // init
    wr_en = 0; rd_en = 0; wdata = 0;
    g_head = 0; g_tail = 0; g_size = 0;

    rst_n = 0;
    repeat (3) @(posedge clk);
    rst_n = 1;
    $display("Reset released.");

    // 1) 先写满一半
    for (i = 0; i < 8; i = i + 1) push(i[WIDTH-1:0]);

    // 2) 读几个
    for (i = 0; i < 4; i = i + 1) pop();

    // 3) 再写一些
    for (i = 100; i < 110; i = i + 1) push(i[WIDTH-1:0]);

    // 4) 随机混合读写
    for (k = 0; k < 50; k = k + 1) begin
      if ($urandom_range(0, 1) == 0)
        push($urandom());
      else
        pop();
    end

    // 5) 把剩下的读空
    while (g_size > 0) pop();

    $display("All tests passed. g_size=%0d", g_size);
    $finish;
  end

endmodule
