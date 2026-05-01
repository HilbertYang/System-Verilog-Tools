module vending_machine (
    input  logic clk,
    input  logic rst_n,
    input  logic nickel,
    input  logic dime,
    output logic dispense,
    output logic change
);
    typedef enum logic [2:0] {S0, S5, S10, S15, S20} state_t;
    state_t curr, next;

    // state register
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) curr <= S0;
        else        curr <= next;
    end

    // next-state logic
    always_comb begin
        case (curr)
            S0:  begin
                if      (nickel) next = S5;
                else if (dime)   next = S10;
                else             next = S0;
            end
            S5:  begin
                if      (nickel) next = S10;
                else if (dime)   next = S15;
                else             next = S5;
            end
            S10: begin
                if      (nickel) next = S15;
                else if (dime)   next = S20;
                else             next = S10;
            end
            S15: next = S0;
            S20: next = S0;
            default: next = S0;
        endcase
    end

    // Moore outputs
    assign dispense = (curr == S15) || (curr == S20);
    assign change   = (curr == S20);

endmodule
