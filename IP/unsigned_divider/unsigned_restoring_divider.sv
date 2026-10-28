`timescale 1ns/1ps

module unsigned_restoring_divider #(
    parameter int DATA_WIDTH = 8
)(
    input  logic                  clk,
    input  logic                  rst_n,

    input  logic                  start,
    output logic                  ready,
    output logic                  busy,
    output logic                  done,

    input  logic [DATA_WIDTH-1:0] dividend,
    input  logic [DATA_WIDTH-1:0] divisor,

    output logic [DATA_WIDTH-1:0] quotient,
    output logic [DATA_WIDTH-1:0] remainder,
    output logic                  div_by_zero
);

    localparam int ITER_WIDTH = (DATA_WIDTH <= 1) ? 1 : $clog2(DATA_WIDTH);
    localparam logic [ITER_WIDTH-1:0] LAST_ITER = ITER_WIDTH'(DATA_WIDTH - 1);

    logic [DATA_WIDTH-1:0] quotient_work;
    logic [DATA_WIDTH-1:0] remainder_work;
    logic [DATA_WIDTH-1:0] divisor_reg;
    logic [ITER_WIDTH-1:0] iteration;

    logic [DATA_WIDTH:0]   remainder_shifted;
    logic [DATA_WIDTH-1:0] quotient_shifted;

    assign ready = !busy;

    // Generate one quotient bit per cycle.
    always_comb begin
        remainder_shifted = {remainder_work, quotient_work[DATA_WIDTH-1]};
        quotient_shifted  = quotient_work << 1;

        if (remainder_shifted >= {1'b0, divisor_reg}) begin
            remainder_shifted   = remainder_shifted - {1'b0, divisor_reg};
            quotient_shifted[0] = 1'b1;
        end
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            busy           <= 1'b0;
            done           <= 1'b0;
            quotient       <= '0;
            remainder      <= '0;
            div_by_zero    <= 1'b0;
            quotient_work  <= '0;
            remainder_work <= '0;
            divisor_reg    <= '0;
            iteration      <= '0;
        end else begin
            done <= 1'b0;

            if (!busy) begin
                if (start) begin
                    div_by_zero <= (divisor == '0);

                    if (divisor == '0) begin
                        quotient  <= '0;
                        remainder <= dividend;
                        done      <= 1'b1;
                    end else begin
                        quotient_work  <= dividend;
                        remainder_work <= '0;
                        divisor_reg    <= divisor;
                        iteration      <= '0;
                        busy           <= 1'b1;
                    end
                end
            end else begin
                quotient_work  <= quotient_shifted;
                remainder_work <= remainder_shifted[DATA_WIDTH-1:0];

                if (iteration == LAST_ITER) begin
                    quotient  <= quotient_shifted;
                    remainder <= remainder_shifted[DATA_WIDTH-1:0];
                    busy      <= 1'b0;
                    done      <= 1'b1;
                end else begin
                    iteration <= iteration + 1'b1;
                end
            end
        end
    end

endmodule

