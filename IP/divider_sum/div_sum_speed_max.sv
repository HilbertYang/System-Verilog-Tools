`timescale 1ns/1ps

module div_sum_speed_max #(
    parameter int DATA_WIDTH = 16
)(
    input  logic                  clk,
    input  logic                  rst_n,

    input  logic                  in_valid,
    output logic                  in_ready,
    input  logic [DATA_WIDTH-1:0] a,
    input  logic [DATA_WIDTH-1:0] b,
    input  logic [DATA_WIDTH-1:0] c,
    input  logic [DATA_WIDTH-1:0] d,
    input  logic [DATA_WIDTH-1:0] e,
    input  logic [DATA_WIDTH-1:0] f,

    output logic                  out_valid,
    input  logic                  out_ready,
    output logic [DATA_WIDTH+1:0] out,
    output logic                  div_by_zero
);

    localparam int OUT_WIDTH = DATA_WIDTH + 2;

    logic [DATA_WIDTH-1:0] quotient_ab_next;
    logic [DATA_WIDTH-1:0] quotient_cd_next;
    logic [DATA_WIDTH-1:0] quotient_ef_next;

    logic [DATA_WIDTH-1:0] quotient_ab_s1;
    logic [DATA_WIDTH-1:0] quotient_cd_s1;
    logic [DATA_WIDTH-1:0] quotient_ef_s1;
    logic                  div_by_zero_s1;
    logic                  s1_valid;

    logic stage2_ready;
    logic input_hs;
    logic s1_hs;

    assign stage2_ready = !out_valid || out_ready;
    assign in_ready     = !s1_valid || stage2_ready;
    assign input_hs     = in_valid && in_ready;
    assign s1_hs        = s1_valid && stage2_ready;

    // Three independent divisions are inferred in parallel.
    always_comb begin
        quotient_ab_next = (b == '0) ? '0 : (a / b);
        quotient_cd_next = (d == '0) ? '0 : (c / d);
        quotient_ef_next = (f == '0) ? '0 : (e / f);
    end

    // Stage 1: parallel division results.
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            quotient_ab_s1 <= '0;
            quotient_cd_s1 <= '0;
            quotient_ef_s1 <= '0;
            div_by_zero_s1 <= 1'b0;
            s1_valid       <= 1'b0;
        end else if (input_hs) begin
            quotient_ab_s1 <= quotient_ab_next;
            quotient_cd_s1 <= quotient_cd_next;
            quotient_ef_s1 <= quotient_ef_next;
            div_by_zero_s1 <= (b == '0) || (d == '0) || (f == '0);
            s1_valid       <= 1'b1;
        end else if (s1_hs) begin
            s1_valid <= 1'b0;
        end
    end

    // Stage 2: balanced-width sum and output register.
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            out         <= '0;
            out_valid   <= 1'b0;
            div_by_zero <= 1'b0;
        end else if (s1_hs) begin
            out <= {{(OUT_WIDTH-DATA_WIDTH){1'b0}}, quotient_ab_s1} +
                   {{(OUT_WIDTH-DATA_WIDTH){1'b0}}, quotient_cd_s1} +
                   {{(OUT_WIDTH-DATA_WIDTH){1'b0}}, quotient_ef_s1};
            out_valid   <= 1'b1;
            div_by_zero <= div_by_zero_s1;
        end else if (out_valid && out_ready) begin
            out_valid <= 1'b0;
        end
    end

endmodule
