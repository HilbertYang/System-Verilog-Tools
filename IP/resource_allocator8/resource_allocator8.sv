module resource_allocator8 (
    input  logic            clk,
    input  logic            rst_n,

    input  logic [1:0]      alloc_req,
    input  logic [7:0]      release_mask,

    output logic [1:0]      alloc_ok,
    output logic [1:0][2:0] alloc_id,
    output logic [7:0]      free_mask
);
  logic [3:0] free_cnt;
  logic [1:0] req_cnt;
  logic [7:0] run_mask;
  logic [1:0][2:0] least_2free;
  logic [2:0] least_1free;
  assign run_mask = free_mask | release_mask;
  always_comb begin
    free_cnt = '0;
    req_cnt  = '0;
    least_2free = least_2significant_bit(run_mask);
    least_1free = least_significant_bit(run_mask);
    for(int i = 0; i < 8; i++)begin
      free_cnt = run_mask[i] + free_cnt;
    end
    for(int i = 0; i < 2; i++ )begin
      req_cnt = alloc_req[i] + req_cnt;
    end

  end

  function automatic logic [1:0][2:0] least_2significant_bit(
    input logic [7:0] mask
  );
    logic [7:0] mask_copy;
    least_2significant_bit = '0;
    mask_copy = mask;
    least_2significant_bit[0] = least_significant_bit(mask_copy);
    mask_copy[least_2significant_bit[0]] = 1'b0;
    least_2significant_bit[1] = least_significant_bit(mask_copy);
  endfunction
  
  function automatic logic [2:0] least_significant_bit(
    input logic [7:0] mask
  );
    least_significant_bit = 3'd0;
      for(int i = 7; i >=0 ; i--)begin
        if(mask[i])
          least_significant_bit = i;
      end
  endfunction

  always_ff@(posedge clk )begin
    if(!rst_n)begin
      alloc_ok <= '0;
      alloc_id <= '0;
      free_mask <= 8'hFF;
    end else begin
      free_mask <= run_mask;
      alloc_id <= '0;
      alloc_ok <= '0;
      if(req_cnt == 2)begin
        if(free_cnt >= 2)begin
          alloc_ok <= 2'b11;
          alloc_id <= least_2free;
          free_mask[least_2free[0]] <= 1'b0;
          free_mask[least_2free[1]] <= 1'b0;
        end else if(free_cnt == 1)begin
          alloc_ok <= 2'b01;
          alloc_id[0] <= least_1free;
          free_mask[least_1free] <= 1'b0;
        end else begin
          alloc_ok <= '0;
          alloc_id <= '0;
        end
      end else if (req_cnt == 1)begin
        if(free_cnt >= 1) begin
          alloc_ok <= alloc_req;
          alloc_id[alloc_req-1] <= least_1free;
          free_mask[least_1free] <= 1'b0;
        end else begin
          alloc_ok <= '0;
          alloc_id <= '0;
        end
      end else begin
        
      end
    end
  end
endmodule
