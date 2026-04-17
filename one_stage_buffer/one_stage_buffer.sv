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

    logic        buf_valid;
    logic [31:0] buf_data;

    // in_ready: buffer is empty, or downstream takes data this cycle (making room)
    // Expression: in_ready = ~buf_valid | out_ready
    assign in_ready  = ~buf_valid | out_ready;
    assign out_valid = buf_valid;
    assign out_data  = buf_data;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            buf_valid <= 1'b0;
            buf_data  <= 32'b0;
        end else begin
            if (buf_valid && out_ready) begin
                // downstream consumes data; simultaneously accept new data if available
                buf_valid <= in_valid;
                buf_data  <= in_data;
            end else if (!buf_valid && in_valid) begin
                buf_valid <= 1'b1;
                buf_data  <= in_data;
            end
        end
    end

endmodule
