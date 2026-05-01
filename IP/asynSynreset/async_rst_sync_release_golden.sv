module async_rst_sync_release (
    input  logic clk,
    input  logic arst_n,
    output logic srst_n
);
    logic ff1, ff2;

    always_ff @(posedge clk or negedge arst_n) begin
        if (~arst_n) begin
            ff1 <= 1'b0;
            ff2 <= 1'b0;
        end else begin
            ff1 <= 1'b1;
            ff2 <= ff1;
        end
    end

    assign srst_n = ff2;

endmodule
