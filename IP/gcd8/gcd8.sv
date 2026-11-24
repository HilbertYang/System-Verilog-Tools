module gcd8 (
    input  logic       clk,
    input  logic       rst_n,
    input  logic       start,
    input  logic [7:0] a,
    input  logic [7:0] b,

    output logic       busy,
    output logic       done,
    output logic [7:0] result
);
    function automatic logic [7:0] find_max(
        input logic [7:0] op1,
        input logic [7:0] op2
    );
        if(op1 > op2)
          find_max = op1;
        else
          find_max = op2;
    endfunction  
    function automatic logic [7:0] find_min(
        input logic [7:0] op1,
        input logic [7:0] op2
    );
        if(op1 > op2)
          find_min = op2;
        else
          find_min = op1;
    endfunction 


    logic [7:0] run_a, run_b, tmp_max, tmp_min;
    assign   tmp_max = find_max(run_a, run_b);
    assign   tmp_min = find_min(run_a, run_b);
    always_ff@(posedge clk)begin
      if(!rst_n)begin
        run_a     <= '0;
        run_b     <= '0;
        busy      <= '0;
        done      <= '0;
        result    <= '0;
      end else begin
        if(!busy)begin
            done <= '0;
          if(start)begin
            run_a <= a;
            run_b <= b;
            busy  <= 1'b1;
          end
        end else begin
          if((run_a == run_b)||(run_a == 0)||(run_b == 0))begin
            busy      <= '0;
            done      <= 1'b1;
            if(run_a == 0)begin
              result <= run_b;
            end else begin
              result <= run_a;
            end 
          end
          run_a <= tmp_max - tmp_min;
          run_b <= tmp_min;
        end
        
      end
    end
endmodule

