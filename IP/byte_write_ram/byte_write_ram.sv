module byte_write_ram(
  input   logic         clk,
  input   logic         rst_n,
  
  input   logic         wr_en,
  input   logic [3:0]   wr_addr,
  input   logic [31:0]  wr_data,
  input   logic [3:0]   wr_strb,

  input   logic         rd_en,
  input   logic [3:0]   rd_addr,
  output  logic [31:0]  rd_data,
  output  logic         rd_valid
  );
  
  logic [15:0][31:0] ram;


  always_ff@(posedge clk) begin
    if(~rst_n)begin
      rd_data <= '0;
      rd_valid<= '0;
    end else begin
      rd_valid <= '0;
      if(wr_en)begin
        for(int i = 0; i < 4; i++)begin
          if(wr_strb[i])begin
            ram[wr_addr][i*8 +: 8] <= wr_data[i*8 +: 8];
          end
        end
      end
      if(rd_en)begin
        rd_data <=  ram[rd_addr];
        rd_valid <= 1'b1;
      end
    end
  end

  endmodule
