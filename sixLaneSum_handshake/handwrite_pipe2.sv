// 两级流水版本
// Stage1: 并行算 3 个 pair-sum（ps01, ps23, ps45）
// Stage2: 3 路 partial sum 求总和 → sum
//
// Critical path: 单次加法延迟（vs 原版 5 次串联）

module sixLaneSum_pipe2 (
	input  logic        clk, rst_n,
	input  logic [31:0] indata0, indata1, indata2, indata3, indata4, indata5,
	input  logic        in_valid, out_ready,
	output logic        in_ready, out_valid,
	output logic [31:0] sum
);

logic [31:0] ps01, ps23, ps45;
logic        s1_valid, s1_ready;

logic in_hs, s1_hs, out_hs;
assign in_hs  = in_valid  & in_ready;
assign s1_hs  = s1_valid  & s1_ready;
assign out_hs = out_valid & out_ready;

// 反压：下游本周期会取走，或本级为空，即可接收
assign in_ready = !s1_valid | s1_hs;
assign s1_ready = !out_valid | out_hs;

// Stage 1
always_ff @(posedge clk or negedge rst_n) begin
	if (~rst_n) begin
		{ps01, ps23, ps45} <= '0;
		s1_valid <= 1'b0;
	end else if (in_hs) begin
		ps01     <= indata0 + indata1;
		ps23     <= indata2 + indata3;
		ps45     <= indata4 + indata5;
		s1_valid <= 1'b1;
	end else if (s1_hs) begin
		s1_valid <= 1'b0;
	end
end

// Stage 2
always_ff @(posedge clk or negedge rst_n) begin
	if (~rst_n) begin
		sum       <= '0;
		out_valid <= 1'b0;
	end else if (s1_hs) begin
		sum       <= ps01 + ps23 + ps45;
		out_valid <= 1'b1;
	end else if (out_hs) begin
		out_valid <= 1'b0;
	end
end

endmodule
