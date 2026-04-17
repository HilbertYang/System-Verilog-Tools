// 6-lane 32-bit adder with upstream/downstream handshake
//
// Critical path note: chained 5-addition tree has ~5 adder delays.
// Pipeline option: Stage1 computes 3 pair-sums in parallel (a+b, c+d, e+f),
// Stage2 sums the three partials — cuts critical path roughly in half.
//
// This implementation is single-cycle (no pipeline).

module sixLaneSum_handshake (
    input  logic        clk, rst_n,
    // upstream
    input  logic        in_valid,
    input  logic [31:0] in_data0, in_data1, in_data2, in_data3, in_data4, in_data5,
    output logic        in_ready,
    // downstream
    output logic        out_valid,
    output logic [31:0] sum,
    input  logic        out_ready
);

logic in_hs, out_hs;
assign in_hs  = in_valid  & in_ready;
assign out_hs = out_valid & out_ready;

assign in_ready = !out_valid | out_hs;

wire [31:0] sum_next = (in_data0 + in_data1) +
                       (in_data2 + in_data3) +
                       (in_data4 + in_data5);

always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        sum       <= '0;
        out_valid <= 1'b0;
    end else if (in_hs) begin
        sum       <= sum_next;
        out_valid <= 1'b1;
    end else if (out_hs) begin
        out_valid <= 1'b0;
    end
end

endmodule
