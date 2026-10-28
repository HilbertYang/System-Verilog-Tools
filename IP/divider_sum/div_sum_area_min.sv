`timescale 1ns/1ps

module div_sum_area_min #(
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

    typedef enum logic [1:0] {
        IDLE,
        START_DIV,
        WAIT_DIV,
        HOLD
    } state_t;

    state_t state;

    logic [1:0] pair_index;

    logic [DATA_WIDTH-1:0] c_hold;
    logic [DATA_WIDTH-1:0] d_hold;
    logic [DATA_WIDTH-1:0] e_hold;
    logic [DATA_WIDTH-1:0] f_hold;

    logic [DATA_WIDTH-1:0] div_dividend;
    logic [DATA_WIDTH-1:0] div_divisor;
    logic [DATA_WIDTH-1:0] div_quotient;
    logic                  div_start;
    logic                  div_ready;
    logic                  div_busy;
    logic                  div_done;
    logic                  div_zero;
    logic [DATA_WIDTH-1:0] div_remainder;

    logic [OUT_WIDTH-1:0] accumulator;
    logic [OUT_WIDTH-1:0] accumulated_next;
    logic                 div_zero_seen;

    assign in_ready = (state == IDLE);
    assign div_start = (state == START_DIV);
    assign accumulated_next = accumulator +
                              {{(OUT_WIDTH-DATA_WIDTH){1'b0}}, div_quotient};

    // Quotient is the only arithmetic result needed by this wrapper.
    wire _unused_divider_outputs = &{1'b0, div_busy, div_remainder};

    // A single divider instance is time-multiplexed across all three pairs.
    unsigned_restoring_divider #(
        .DATA_WIDTH(DATA_WIDTH)
    ) u_divider (
        .clk         (clk),
        .rst_n       (rst_n),
        .start       (div_start),
        .ready       (div_ready),
        .busy        (div_busy),
        .done        (div_done),
        .dividend    (div_dividend),
        .divisor     (div_divisor),
        .quotient    (div_quotient),
        .remainder   (div_remainder),
        .div_by_zero (div_zero)
    );

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state            <= IDLE;
            pair_index       <= '0;
            c_hold           <= '0;
            d_hold           <= '0;
            e_hold           <= '0;
            f_hold           <= '0;
            div_dividend      <= '0;
            div_divisor       <= '0;
            accumulator      <= '0;
            div_zero_seen    <= 1'b0;
            out_valid        <= 1'b0;
            out              <= '0;
            div_by_zero      <= 1'b0;
        end else begin
            case (state)
                IDLE: begin
                    if (in_valid) begin
                        pair_index    <= '0;
                        c_hold        <= c;
                        d_hold        <= d;
                        e_hold        <= e;
                        f_hold        <= f;
                        div_dividend   <= a;
                        div_divisor    <= b;
                        accumulator   <= '0;
                        div_zero_seen <= 1'b0;
                        div_by_zero   <= 1'b0;
                        state         <= START_DIV;
                    end
                end

                START_DIV: begin
                    if (div_ready) begin
                        state <= WAIT_DIV;
                    end
                end

                WAIT_DIV: begin
                    if (div_done) begin
                        accumulator <= accumulated_next;
                        div_zero_seen <= div_zero_seen | div_zero;

                        case (pair_index)
                            2'd0: begin
                                pair_index   <= 2'd1;
                                div_dividend <= c_hold;
                                div_divisor  <= d_hold;
                                state        <= START_DIV;
                            end

                            2'd1: begin
                                pair_index   <= 2'd2;
                                div_dividend <= e_hold;
                                div_divisor  <= f_hold;
                                state        <= START_DIV;
                            end

                            default: begin
                                out         <= accumulated_next;
                                out_valid   <= 1'b1;
                                div_by_zero <= div_zero_seen | div_zero;
                                state       <= HOLD;
                            end
                        endcase
                    end
                end

                HOLD: begin
                    if (out_ready) begin
                        out_valid <= 1'b0;
                        state     <= IDLE;
                    end
                end

                default: begin
                    state     <= IDLE;
                    out_valid <= 1'b0;
                end
            endcase
        end
    end

endmodule
