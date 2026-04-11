// ===========================================================================
// Asynchronous FIFO (Dual Clock Domain)
//
// Cross-domain pointer synchronization strategy:
//   1. Convert binary pointers to Gray code before crossing clock domains.
//      Gray code changes only 1 bit per count, so a 2-FF synchronizer
//      cannot capture a spurious intermediate value.
//   2. Synchronize Gray-coded pointers with a 2-flop synchronizer.
//
// Full / empty detection:
//   - empty (in rd_clk domain): rd_gray == synchronized wr_gray
//   - full  (in wr_clk domain): top two bits inverted, remaining bits equal
//       => wr_gray == {~rd_gray_sync[MSB:MSB-1], rd_gray_sync[MSB-2:0]}
// ===========================================================================
module async_fifo #(
    parameter DATA_WIDTH = 8,
    parameter DEPTH      = 16,
    parameter ADDR_WIDTH = $clog2(DEPTH)
)(
    // Write clock domain
    input  wire                  wr_clk,
    input  wire                  wr_rst_n,
    input  wire                  wr_en,
    input  wire [DATA_WIDTH-1:0] wr_data,
    output wire                  full,

    // Read clock domain
    input  wire                  rd_clk,
    input  wire                  rd_rst_n,
    input  wire                  rd_en,
    output reg  [DATA_WIDTH-1:0] rd_data,
    output wire                  empty
);

    // Dual-port RAM: written in wr_clk domain, read in rd_clk domain
    reg [DATA_WIDTH-1:0] mem [0:DEPTH-1];

    // Write domain: binary + Gray pointers
    reg [ADDR_WIDTH:0] wr_bin;
    reg [ADDR_WIDTH:0] wr_gray;

    // Read domain: binary + Gray pointers
    reg [ADDR_WIDTH:0] rd_bin;
    reg [ADDR_WIDTH:0] rd_gray;

    // 2-FF synchronizer: wr_gray -> rd_clk domain
    reg [ADDR_WIDTH:0] wr_gray_sync1_rd, wr_gray_sync2_rd;

    // 2-FF synchronizer: rd_gray -> wr_clk domain
    reg [ADDR_WIDTH:0] rd_gray_sync1_wr, rd_gray_sync2_wr;

    // Next-pointer combinational logic
    wire [ADDR_WIDTH:0] wr_bin_next  = wr_bin + 1;
    wire [ADDR_WIDTH:0] wr_gray_next = wr_bin_next ^ (wr_bin_next >> 1);

    wire [ADDR_WIDTH:0] rd_bin_next  = rd_bin + 1;
    wire [ADDR_WIDTH:0] rd_gray_next = rd_bin_next ^ (rd_bin_next >> 1);

    // Write domain logic
    always @(posedge wr_clk or negedge wr_rst_n) begin
        if (!wr_rst_n) begin
            wr_bin  <= 0;
            wr_gray <= 0;
        end else if (wr_en && !full) begin
            mem[wr_bin[ADDR_WIDTH-1:0]] <= wr_data;
            wr_bin  <= wr_bin_next;
            wr_gray <= wr_gray_next;
        end
    end

    // Synchronize wr_gray into rd_clk domain
    always @(posedge rd_clk or negedge rd_rst_n) begin
        if (!rd_rst_n) begin
            wr_gray_sync1_rd <= 0;
            wr_gray_sync2_rd <= 0;
        end else begin
            wr_gray_sync1_rd <= wr_gray;
            wr_gray_sync2_rd <= wr_gray_sync1_rd;
        end
    end

    // Read domain logic
    always @(posedge rd_clk or negedge rd_rst_n) begin
        if (!rd_rst_n) begin
            rd_bin  <= 0;
            rd_gray <= 0;
            rd_data <= 0;
        end else if (rd_en && !empty) begin
            rd_data <= mem[rd_bin[ADDR_WIDTH-1:0]];
            rd_bin  <= rd_bin_next;
            rd_gray <= rd_gray_next;
        end
    end

    // Synchronize rd_gray into wr_clk domain
    always @(posedge wr_clk or negedge wr_rst_n) begin
        if (!wr_rst_n) begin
            rd_gray_sync1_wr <= 0;
            rd_gray_sync2_wr <= 0;
        end else begin
            rd_gray_sync1_wr <= rd_gray;
            rd_gray_sync2_wr <= rd_gray_sync1_wr;
        end
    end

    // empty: pointers are equal (compared in rd_clk domain)
    assign empty = (rd_gray == wr_gray_sync2_rd);

    // full: top two bits inverted, lower bits equal (compared in wr_clk domain)
    assign full = (wr_gray == {~rd_gray_sync2_wr[ADDR_WIDTH:ADDR_WIDTH-1],
                                 rd_gray_sync2_wr[ADDR_WIDTH-2:0]});

endmodule
