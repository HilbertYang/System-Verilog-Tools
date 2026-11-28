module lru4 (
    input  logic       clk,
    input  logic       rst_n,

    input  logic       touch_valid,
    input  logic [1:0] touch_way,
    input  logic [3:0] invalidate_mask,

    output logic [3:0] valid_mask,
    output logic [1:0] victim_way
);
  typedef struct packed{
    logic [1:0] order;
  } entry_t;
  entry_t [3:0] ram;
  
  logic [1:0] sel_order;
  logic have_invalid;
  logic [1:0] min_order_way, order_is_three_way;
  
  assign have_invalid = !(&valid_mask);
  assign sel_order = ram[touch_way].order;
  assign victim_way = have_invalid ? min_order_way : order_is_three_way;
  
  always_comb begin
    min_order_way         = 2'd0;
    order_is_three_way    = 2'd0;

    for(int i = 3 ; i >= 0; i--)begin
      if(!valid_mask[i])begin
        min_order_way = i[1:0];
      end
      if(ram[i].order == 2'd3)begin
        order_is_three_way = i[1:0];
      end
    end
  end

  always_ff@(posedge clk)begin
    if(!rst_n)begin
      valid_mask <= '0;
      for(int i = 0; i <= 3; i++)begin
        ram[i].order <= 2'd3 - i[1:0];
      end
    end else begin
      if((|invalidate_mask))begin
        valid_mask <=  valid_mask & (~invalidate_mask);
      end
      if(touch_valid)begin
        ram[touch_way].order <= '0;
        valid_mask[touch_way] <= 1'b1;
        for(int i = 0; i <= 3; i++)begin
          if(ram[i].order < sel_order)begin
            ram[i].order <= ram[i].order + 2'b1;
          end
        end
      end
    end
  end



endmodule
