// ===========================================================================
// Clock Dividers
//
// 1. clk_div_even  - Even division, 50% duty cycle, posedge-triggered only
// 2. clk_div_odd   - Odd division, 50% duty cycle
//      Two counters (posedge / negedge) each drive a signal high for
//      floor(N/2) cycles. Staggered by half an input cycle, their OR
//      produces exactly N/2 high cycles and N/2 low cycles per period.
// 3. clk_divider   - General divider; selects even/odd via generate
// ===========================================================================


// ---------------------------------------------------------------------------
// 1. Even frequency divider  (N must be even)
// ---------------------------------------------------------------------------
module clk_div_even #(
    parameter N = 4
)(
    input  wire clk,
    input  wire rst_n,
    output reg  clk_div
);
    localparam CNT_W = $clog2(N);

    reg [CNT_W-1:0] cnt;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cnt     <= 0;
            clk_div <= 0;
        end else if (cnt == N/2 - 1) begin
            cnt     <= 0;
            clk_div <= ~clk_div;
        end else begin
            cnt <= cnt + 1;
        end
    end
endmodule


// ---------------------------------------------------------------------------
// 2. Odd frequency divider  (N must be odd, N >= 3), 50% duty cycle
//
//    Example N=3:
//      clk_pos high: t = 0   .. T      (1 cycle, floor(3/2)=1)
//      clk_neg high: t = 0.5T.. 1.5T  (1 cycle, shifted by half period)
//      OR    high:   t = 0   .. 1.5T  => 50% duty cycle
// ---------------------------------------------------------------------------
module clk_div_odd #(
    parameter N = 3
)(
    input  wire clk,
    input  wire rst_n,
    output wire clk_div
);
    localparam CNT_W = $clog2(N);

    reg [CNT_W-1:0] cnt_pos;
    reg [CNT_W-1:0] cnt_neg;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) cnt_pos <= 0;
        else        cnt_pos <= (cnt_pos == N-1) ? 0 : cnt_pos + 1;
    end

    always @(negedge clk or negedge rst_n) begin
        if (!rst_n) cnt_neg <= 0;
        else        cnt_neg <= (cnt_neg == N-1) ? 0 : cnt_neg + 1;
    end

    assign clk_div = (cnt_pos < N/2) | (cnt_neg < N/2);

endmodule


// ---------------------------------------------------------------------------
// 3. General clock divider  (works for any N >= 2)
// ---------------------------------------------------------------------------
module clk_divider #(
    parameter N = 6
)(
    input  wire clk,
    input  wire rst_n,
    output wire clk_div
);
    generate
        if (N % 2 == 0) begin : gen_even
            localparam CNT_W = $clog2(N);
            reg [CNT_W-1:0] cnt;
            reg clk_out;

            always @(posedge clk or negedge rst_n) begin
                if (!rst_n) begin
                    cnt     <= 0;
                    clk_out <= 0;
                end else if (cnt == N/2 - 1) begin
                    cnt     <= 0;
                    clk_out <= ~clk_out;
                end else begin
                    cnt <= cnt + 1;
                end
            end

            assign clk_div = clk_out;

        end else begin : gen_odd
            localparam CNT_W = $clog2(N);
            reg [CNT_W-1:0] cnt_pos;
            reg [CNT_W-1:0] cnt_neg;

            always @(posedge clk or negedge rst_n) begin
                if (!rst_n) cnt_pos <= 0;
                else        cnt_pos <= (cnt_pos == N-1) ? 0 : cnt_pos + 1;
            end

            always @(negedge clk or negedge rst_n) begin
                if (!rst_n) cnt_neg <= 0;
                else        cnt_neg <= (cnt_neg == N-1) ? 0 : cnt_neg + 1;
            end

            assign clk_div = (cnt_pos < N/2) | (cnt_neg < N/2);
        end
    endgenerate

endmodule
