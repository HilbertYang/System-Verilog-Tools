module interrupt_controller8(
  input logic clk,
  input logic rst_n,
  input logic [7:0] events,
  input logic [7:0] clear,
  input logic [7:0] mask,

  output logic [7:0] pending,
  output logic       irq,
  output logic [2:0] irq_id
  );

  logic [7:0] buff;

  always_ff@(posedge clk)begin
    if(!rst_n)begin
      pending <= '0;
    end else begin
      for(int i=0; i < 8; i++)begin
        if(clear[i])begin
          pending[i] <= '0;
        end
        if(events[i])begin
          pending[i] <= 1'b1;
        end
      end
    end
  end

  always_comb begin
    irq = '0;
    irq_id = '0;
    buff = ~mask & pending;
    for(int i=7; i >= 0; i--)begin
      irq = irq || buff[i];
      if(buff[i])begin
        irq_id = i;
      end
      
    end
  end
  endmodule
