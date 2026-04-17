// 6-lane 32-bit adder with upstream/downstream handshake
//
// Critical path note: chained 5-addition tree has ~5 adder delays.
// Pipeline option: Stage1 computes 3 pair-sums in parallel (a+b, c+d, e+f),
// Stage2 sums the three partials — cuts critical path roughly in half.
//
// This implementation is single-cycle (no pipeline).

module sixLaneSum_handshake (
    input  logic        clk,
    input  logic        rst_n,
    // upstream
    input  logic        in_valid,
    input  logic [31:0] in_data0,
    input  logic [31:0] in_data1,
    input  logic [31:0] in_data2,
    input  logic [31:0] in_data3,
    input  logic [31:0] in_data4,
    input  logic [31:0] in_data5,
    output logic        in_ready,
    // downstream
    output logic        out_valid,
    output logic [31:0] sum,
    input  logic        out_ready
);

    typedef enum logic { S_IDLE = 1'b0, S_VALID = 1'b1 } state_t;
    state_t state;

    // Can accept new input when idle, or when output is being consumed this cycle
    wire out_hs = out_valid & out_ready;
    wire in_hs  = in_valid  & in_ready;

    assign in_ready = (state == S_IDLE) | out_hs;

    // Adder tree: 3 parallel pair-sums then a 3-input sum keeps critical path short
    wire [31:0] sum_next = (in_data0 + in_data1) +
                           (in_data2 + in_data3) +
                           (in_data4 + in_data5);

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state     <= S_IDLE;
            out_valid <= 1'b0;
            sum       <= 32'h0;
        end else begin
            case (state)
                S_IDLE: begin
                    if (in_hs) begin
                        sum       <= sum_next;
                        out_valid <= 1'b1;
                        state     <= S_VALID;
                    end
                end
                S_VALID: begin
                    if (out_hs) begin
                        if (in_hs) begin
                            sum   <= sum_next; // back-to-back: accept new data immediately
                            // out_valid stays 1, state stays S_VALID
                        end else begin
                            out_valid <= 1'b0;
                            state     <= S_IDLE;
                        end
                    end
                end
            endcase
        end
    end

endmodule
