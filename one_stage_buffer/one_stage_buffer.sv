module one_stage_buffer (
    input  logic        clk, rst_n,
    input  logic        in_valid,
    input  logic [31:0] in_data,
    input  logic        out_ready,
    output logic        in_ready,
    output logic        out_valid,
    output logic [31:0] out_data
);

logic in_hs, out_hs;
assign in_hs  = in_valid & in_ready;
assign out_hs = out_valid & out_ready;

assign in_ready = !out_valid | out_hs;

always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        out_valid <= 1'b0;
        out_data  <= '0;
    end else if (in_hs) begin
        out_data  <= in_data;
        out_valid <= 1'b1;
    end else if (out_hs) begin
        out_valid <= 1'b0;
    end
end

endmodule
