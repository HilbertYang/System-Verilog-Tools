// Async assert, sync release reset synchronizer
//
// Assert (arst_n=0): both FFs clear asynchronously, srst_n goes low immediately
// Release (arst_n=1): srst_n rises only after two clock edges, preventing
//                     metastability and ensuring all FFs leave reset together

module async_rst_sync_release (
    input  logic clk,
    input  logic arst_n,
    output logic srst_n
);

logic ff1, ff2;

	always_ff @(posedge clk or negedge arst_n) begin
	    if (~arst_n) begin
		ff1 <= 1'b0;
		ff2 <= 1'b0;
	    end else begin
		ff1 <= 1'b1;
		ff2 <= ff1;
	    end
	end

	assign srst_n = ff2;

endmodule
