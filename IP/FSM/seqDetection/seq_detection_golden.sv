module seq_detection (
    input  logic clk,
    input  logic rst_n,
    input  logic data_in,
    output logic detected
);
    typedef enum logic [2:0] {
        S0, S1, S2, S3, S4
    } state_t;

    state_t curr, next;

    // state register
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) curr <= S0;
        else        curr <= next;
    end

    // next-state logic
    always_comb begin
        case (curr)
            S0: if (data_in) next = S1; else next = S0;
            S1: if (data_in) next = S1; else next = S2;
            S2: if (data_in) next = S3; else next = S0;
            S3: if (data_in) next = S4; else next = S2;
            S4: if (data_in) next = S1; else next = S2;
            default:         next = S0;
        endcase
    end

    // Moore output
    assign detected = (curr == S4);

endmodule
