module syn_fifo #(
    parameter int DATA_WIDTH = 8,
    parameter int DEPTH      = 8
)(
    input  logic                  clk,
    input  logic                  rst_n,
    input  logic                  wr_en,
    input  logic [DATA_WIDTH-1:0] wr_data,
    input  logic                  rd_en,
    output logic [DATA_WIDTH-1:0] rd_data,
    output logic                  full,
    output logic                  empty
);
    localparam int PTR_WIDTH = $clog2(DEPTH) + 1;

    logic [DATA_WIDTH-1:0] mem [0:DEPTH-1];
    logic [PTR_WIDTH-1:0]  wr_ptr, rd_ptr;

    wire wr_hs = wr_en & ~full;
    wire rd_hs = rd_en & ~empty;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            wr_ptr <= '0;
            rd_ptr <= '0;
        end else begin
            if (wr_hs) begin
                mem[wr_ptr[PTR_WIDTH-2:0]] <= wr_data;
                wr_ptr <= wr_ptr + 1'b1;
            end
            if (rd_hs) begin
                rd_data <= mem[rd_ptr[PTR_WIDTH-2:0]];
                rd_ptr  <= rd_ptr + 1'b1;
            end
        end
    end

    assign full  = (wr_ptr[PTR_WIDTH-1] != rd_ptr[PTR_WIDTH-1]) &&
                   (wr_ptr[PTR_WIDTH-2:0] == rd_ptr[PTR_WIDTH-2:0]);
    assign empty = (wr_ptr == rd_ptr);

endmodule
