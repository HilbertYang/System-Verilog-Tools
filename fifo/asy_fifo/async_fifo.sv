// 4.16.2026 HILBERT
// ASYNFIFO
module async_fifo #(
	parameter int DATA_WIDTH = 8,
	parameter int DEPTH      = 16,
	parameter int ADDR_WIDTH = $clog2(DEPTH)
)(
	// write clock domain
	input  logic                  wr_clk,
	input  logic                  wr_rst_n,
	input  logic                  wr_en,
	input  logic [DATA_WIDTH-1:0] wr_data,
	output logic                  full,

	// read clock domain
	input  logic                  rd_clk,
	input  logic                  rd_rst_n,
	input  logic                  rd_en,
	output logic [DATA_WIDTH-1:0] rd_data,
	output logic                  empty
);

	localparam int PTR_WIDTH = ADDR_WIDTH + 1;

	logic [DATA_WIDTH-1:0] mem [0:DEPTH-1];

	logic [PTR_WIDTH-1:0] wr_bin;
	logic [PTR_WIDTH-1:0] wr_gray;
	logic [PTR_WIDTH-1:0] wr_bin_next;
	logic [PTR_WIDTH-1:0] wr_gray_next;

	logic [PTR_WIDTH-1:0] rd_bin;
	logic [PTR_WIDTH-1:0] rd_gray;
	logic [PTR_WIDTH-1:0] rd_bin_next;
	logic [PTR_WIDTH-1:0] rd_gray_next;

	logic [PTR_WIDTH-1:0] wr_gray_sync1_rd;
	logic [PTR_WIDTH-1:0] wr_gray_sync2_rd;
	logic [PTR_WIDTH-1:0] rd_gray_sync1_wr;
	logic [PTR_WIDTH-1:0] rd_gray_sync2_wr;

	logic [ADDR_WIDTH-1:0] wr_addr;
	logic [ADDR_WIDTH-1:0] rd_addr;

	logic full_next;
	logic empty_next;

	assign wr_addr = wr_bin[ADDR_WIDTH-1:0];
	assign rd_addr = rd_bin[ADDR_WIDTH-1:0];

	assign wr_bin_next  = wr_bin + (PTR_WIDTH'(wr_en && !full));
	assign wr_gray_next = wr_bin_next ^ (wr_bin_next >> 1);
	assign full_next    = (wr_gray_next == {~rd_gray_sync2_wr[PTR_WIDTH-1:PTR_WIDTH-2],rd_gray_sync2_wr[PTR_WIDTH-3:0]});

	assign rd_bin_next  = rd_bin + (PTR_WIDTH'(rd_en && !empty));
	assign rd_gray_next = rd_bin_next ^ (rd_bin_next >> 1);
	assign empty_next   = (rd_gray_next == wr_gray_sync2_rd);

	// DEPTH should be a power of two for Gray-code pointer comparison.
	initial begin
		if ((1 << ADDR_WIDTH) != DEPTH) begin
			$error("async_fifo DEPTH (%0d) must be a power of 2", DEPTH);
		end
	end

	always_ff @(posedge wr_clk or negedge wr_rst_n) begin
		if (!wr_rst_n) begin
			wr_bin  <= '0;
			wr_gray <= '0;
			full    <= 1'b0;
		end else begin
			if (wr_en && !full) begin
				mem[wr_addr] <= wr_data;
			end
			wr_bin  <= wr_bin_next;
			wr_gray <= wr_gray_next;
			full    <= full_next;
		end
	end

	always_ff @(posedge rd_clk or negedge rd_rst_n) begin
		if (!rd_rst_n) begin
			rd_bin  <= '0;
			rd_gray <= '0;
			rd_data <= '0;
			empty   <= 1'b1;
		end else begin
			if (rd_en && !empty) begin
				rd_data <= mem[rd_addr];
			end
			rd_bin <= rd_bin_next;
			rd_gray <= rd_gray_next;
			empty <= empty_next;
		end
	end

	always_ff @(posedge rd_clk or negedge rd_rst_n) begin
		if (!rd_rst_n) begin
			wr_gray_sync1_rd <= '0;
			wr_gray_sync2_rd <= '0;
		end else begin
			wr_gray_sync1_rd <= wr_gray;
			wr_gray_sync2_rd <= wr_gray_sync1_rd;
		end
	end

	always_ff @(posedge wr_clk or negedge wr_rst_n) begin
		if (!wr_rst_n) begin
			rd_gray_sync1_wr <= '0;
			rd_gray_sync2_wr <= '0;
		end else begin
			rd_gray_sync1_wr <= rd_gray;
			rd_gray_sync2_wr <= rd_gray_sync1_wr;
		end
	end

endmodule
