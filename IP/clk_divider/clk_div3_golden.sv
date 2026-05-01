module clk_div3 (
    input  logic clk,
    input  logic rst_n,
    output logic clk_div3
);

    logic [1:0] cnt;
    logic       pos_clk, neg_clk;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) cnt <= 2'd0;
        else        cnt <= (cnt == 2'd2) ? 2'd0 : cnt + 2'd1;
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) pos_clk <= 1'b0;
        else        pos_clk <= (cnt == 2'd0);
    end

    always_ff @(negedge clk or negedge rst_n) begin
        if (!rst_n) neg_clk <= 1'b0;
        else        neg_clk <= (cnt == 2'd1);
    end

    assign clk_div3 = pos_clk | neg_clk;

endmodule
