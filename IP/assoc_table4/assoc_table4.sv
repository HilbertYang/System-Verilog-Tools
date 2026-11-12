module assoc_table4 (
    input  logic       clk,
    input  logic       rst_n,

    input  logic       update_en,
    input  logic       update_delete,
    input  logic [7:0] update_key,
    input  logic [7:0] update_data,
    output logic       update_ok,

    input  logic       lookup_en,
    input  logic [7:0] lookup_key,
    output logic       lookup_valid,
    output logic       lookup_hit,
    output logic [7:0] lookup_data
);
  typedef struct packed {
    logic       valid;
    logic [7:0] key;
    logic [7:0] data;
    } entry_t;

  entry_t ram [3:0];

  typedef struct packed {
    logic       hit;
    logic [1:0] index;
    } cam_result_t;
  cam_result_t update_cam_result, lookup_cam_result;

  assign update_cam_result = cam(ram, update_key);
  assign lookup_cam_result = cam(ram, lookup_key);
  
  function automatic cam_result_t cam(
    input entry_t     entry [3:0],
    input logic [7:0] key);
    cam_result_t result;
    logic [3:0] match;
    result = '0;
    match  = '0;
    for(int i =0; i < 4; i++)begin
      if(entry[i].valid && entry[i].key == key) match[i] = 1'b1;
    end
    result.hit    = |match;
    //result.index  = match[3]*3 + match[2]*2 + match[1]*1;
    result.index[1] = match[2] | match[3];
    result.index[0] = match[1] | match[3];

    return result;
  endfunction

  logic free_found;
  logic [1:0] free_index;

  //free finder
  always_comb begin
      free_found = 1'b0;
      free_index = 2'b00;

      for (int i = 0; i < 4; i++) begin
          if (!ram[i].valid && !free_found) begin
              free_found = 1'b1;
              free_index = 2'(i);
          end
      end
  end
  
  always_ff@(posedge clk)begin
    if(!rst_n)begin
      update_ok     <= '0;
      lookup_valid  <= '0;
      lookup_hit    <= '0;
      lookup_data   <= '0;
      //ram           <= '{default: '0};
      for(int i =0; i < 4; i++)begin
        ram[i] <= '0;
      end
    end else begin
      lookup_valid <=  '0;
      update_ok <= '0;
      if(update_en)begin
        if(update_delete)begin
        //TODO: delete
          if(update_cam_result.hit)begin
            ram[update_cam_result.index] <= '0;
            update_ok <= 1'b1;
          end
        end else begin
        //TODO: update/replace
          if(update_cam_result.hit)begin
            ram[update_cam_result.index].data  <= update_data;
            update_ok <= 1'b1;
          end else begin
            if(free_found)begin
            //TODO: not full
            update_ok <= 1'b1;
            ram[free_index].valid   <= 1'b1;
            ram[free_index].data    <= update_data;
            ram[free_index].key     <= update_key;
            end
          end
        end
      end

      if(lookup_en)begin
        //TODO: lookup
          lookup_valid <= 1'b1;
        if(lookup_cam_result.hit)begin
          lookup_hit <= 1'b1;
          lookup_data <= ram[lookup_cam_result.index].data;
        end else begin
          lookup_hit <='0;
          lookup_data <= '0;
        end
      end
    end
  end
endmodule

