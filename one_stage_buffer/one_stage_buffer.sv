module one_stage_buffer (
    input  logic        clk,
    input  logic        rst_n,
    input  logic        in_valid,
    input  logic [31:0] in_data,
    input  logic        out_ready,

    output logic        in_ready,
    output logic        out_valid,
    output logic [31:0] out_data
);


    // in_ready: buffer is empty, or downstream takes data this cycle (making room)
    // Expression: in_ready = ~buf_valid | out_ready
    assign in_ready  = ~out_valid || (out_valid && out_ready) ;


    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            out_valid <= 1'b0;
            out_data  <= 32'b0;
        end else begin
            if (out_valid && out_ready) begin
                // downstream consumes data; simultaneously accept new data if available
                out_valid <= in_valid;
                out_data  <= in_data;
            end else if (!out_valid && in_valid) begin
                out_valid <= 1'b1;
                out_data  <= in_data;
            end
        end
    end

endmodule
