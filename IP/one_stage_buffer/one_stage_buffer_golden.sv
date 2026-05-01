module one_stage_buffer #(
    parameter int DATA_WIDTH = 8
)(
    input  logic                  clk,
    input  logic                  rst_n,
    input  logic                  in_valid,
    input  logic [DATA_WIDTH-1:0] in_data,
    input  logic                  out_ready,
    output logic                  in_ready,
    output logic                  out_valid,
    output logic [DATA_WIDTH-1:0] out_data
);
    wire in_hs  = in_valid  & in_ready;
    wire out_hs = out_valid & out_ready;

    // in_ready: accept when empty, or when downstream consumes this cycle
    assign in_ready = ~out_valid | out_hs;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            out_valid <= 1'b0;
            out_data  <= '0;
        end else begin
            if (in_hs)
                out_data <= in_data;
            if (in_hs)
                out_valid <= 1'b1;
            else if (out_hs)
                out_valid <= 1'b0;
        end
    end

endmodule
