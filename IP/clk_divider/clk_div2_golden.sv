module clk_div2 (
    input  logic clk,
    input  logic rst_n,
    output logic clk_div2
);

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) clk_div2 <= 1'b0;
        else        clk_div2 <= ~clk_div2;
    end

endmodule
