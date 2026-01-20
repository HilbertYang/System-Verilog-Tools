module tb_fifo;

  localparam int WIDTH = 8;
  localparam int DEPTH = 16;

  logic clk, rst_n;
  logic wr_en, rd_en;
  logic [WIDTH-1:0] wdata;
  logic [WIDTH-1:0] rdata;
  logic full, empty;
  logic [$clog2(DEPTH+1)-1:0] count;

  fifo_sync #(.WIDTH(WIDTH), .DEPTH(DEPTH)) dut (
    .clk, .rst_n,
    .wr_en, .wdata, .full,
    .rd_en, .rdata, .empty,
    .count
  );

  // clock
  initial clk = 0;
  always #5 clk = ~clk;

  // 黄金模型：用 SystemVerilog queue 记录写进去的顺序
  logic [WIDTH-1:0] golden_q[$];

  // 小工具：push/pop（Day1先用task，不上class）
  task automatic push(input logic [WIDTH-1:0] d);
    @(negedge clk);
    wr_en <= 1;
    wdata <= d;
    rd_en <= 0;
    @(posedge clk);
    // 写成功才入队列
    if (!full) golden_q.push_back(d);
    @(negedge clk);
    wr_en <= 0;
  endtask

  task automatic pop();
    logic [WIDTH-1:0] expect;
    @(negedge clk);
    rd_en <= 1;
    wr_en <= 0;
    @(posedge clk);
    if (!empty) begin
      // 注意：同步读时 rdata 在这个posedge更新
      expect = golden_q.pop_front();
      if (rdata !== expect) begin
        $display("[FAIL] time=%0t rdata=%0h expect=%0h", $time, rdata, expect);
        $fatal(1);
      end else begin
        $display("[PASS] time=%0t rdata=%0h", $time, rdata);
      end
    end
    @(negedge clk);
    rd_en <= 0;
  endtask

  // 主流程
  initial begin
    // init
    wr_en = 0; rd_en = 0; wdata = '0;
    rst_n = 0;
    repeat (3) @(posedge clk);
    rst_n = 1;
    $display("Reset released.");

    // 1) 先写满一半
    for (int i = 0; i < 8; i++) push(i);

    // 2) 读几个
    for (int i = 0; i < 4; i++) pop();

    // 3) 再写一些
    for (int i = 100; i < 110; i++) push(i[WIDTH-1:0]);

    // 4) 随机混合读写（Day1先简单：随机选择push/pop）
    for (int k = 0; k < 50; k++) begin
      if ($urandom_range(0, 1) == 0) begin
        push($urandom());
      end else begin
        pop();
      end
    end

    // 5) 把剩下的读空
    while (golden_q.size() > 0) pop();

    $display("All tests passed. golden_q.size=%0d", golden_q.size());
    $finish;
  end

endmodule
