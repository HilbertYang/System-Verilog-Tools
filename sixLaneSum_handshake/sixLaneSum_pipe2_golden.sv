module sixLaneSum_pipe2 (
    input  logic        clk, rst_n,
    input  logic        in_valid,
    input  logic [31:0] in_data0, in_data1, in_data2, in_data3, in_data4, in_data5,
    input  logic        out_ready,
    output logic        in_ready,
    output logic        out_valid,
    output logic [31:0] sum
);
    logic [31:0] ps01, ps23, ps45;
    logic        s1_valid;

    wire s1_ready = ~out_valid | out_hs;
    wire in_hs    = in_valid  & in_ready;
    wire s1_hs    = s1_valid  & s1_ready;
    wire out_hs   = out_valid & out_ready;

    assign in_ready = ~s1_valid | s1_hs;

    // Stage 1: three parallel pair-sums
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            s1_valid <= 1'b0;
            ps01     <= '0;
            ps23     <= '0;
            ps45     <= '0;
        end else if (in_hs) begin
            ps01     <= in_data0 + in_data1;
            ps23     <= in_data2 + in_data3;
            ps45     <= in_data4 + in_data5;
            s1_valid <= 1'b1;
        end else if (s1_hs) begin
            s1_valid <= 1'b0;
        end
    end

    // Stage 2: final sum
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            out_valid <= 1'b0;
            sum       <= '0;
        end else if (s1_hs) begin
            sum       <= ps01 + ps23 + ps45;
            out_valid <= 1'b1;
        end else if (out_hs) begin
            out_valid <= 1'b0;
        end
    end

endmodule
