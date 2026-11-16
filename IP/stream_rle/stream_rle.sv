module stream_rle (
    input  logic       clk,
    input  logic       rst_n,

    input  logic [7:0] in_data,
    input  logic       in_valid,
    output logic       in_ready,

    input  logic       flush_valid,
    output logic       flush_ready,

    output logic [7:0] out_data,
    output logic [7:0] out_count,
    output logic       out_valid,
    input  logic       out_ready
);

    logic run_valid;
    logic in_hs, out_hs, flush_hs;
    logic out_space;
    logic [7:0] run_data, run_count;
    assign in_hs    = in_valid && in_ready;
    assign out_hs   = out_valid && out_ready;
    assign flush_hs = flush_valid && flush_ready;
    assign out_space  = !out_valid || out_ready;
    assign in_ready   = !flush_valid && 
                        (!run_valid ||
                        ((in_data == run_data) && (run_count < 8'd255))||
                        out_space);
    assign flush_ready = !run_valid || out_space;
   


    always_ff@(posedge clk)begin
      if(!rst_n)begin
        out_data <= '0;
        out_count <= '0;
        out_valid <= '0;
        run_valid <= '0;
        run_data  <= '0;
        run_count <= '0;
      end else begin
        if(out_hs)begin
          out_valid <= '0;
        end
        
        if(flush_hs)begin
          if(run_valid)begin
            out_data <= run_data;
            out_count<= run_count;
            out_valid<= 1'b1;
            run_valid<= '0;
          end else begin
            
          end
        end else if(in_hs) begin
          if(run_valid)begin
            if(in_data != run_data)begin
              run_data <= in_data;
              run_count<= 8'b1;
              out_data <= run_data;
              out_count<= run_count;
              out_valid<= 1'b1;
              run_valid<= 1'b1;
            end else begin
              if(run_count == 8'd255)begin
                out_data <= run_data;
                out_count <= run_count;
                out_valid <= run_valid;
                run_count <= 8'b1;
              end else begin
                run_count<= run_count + 1'b1;
              end
            end
          end else begin
            run_data <= in_data;
            run_valid<= 1'b1;
            run_count<= 8'b1;
          end
        end
      end
    end
endmodule
