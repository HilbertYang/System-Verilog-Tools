module spi_master8 (
    input  logic       clk,
    input  logic       rst_n,

    input  logic       start,
    input  logic [7:0] tx_data,
    input  logic [7:0] cfg_half_period,

    output logic       busy,
    output logic       done,
    output logic [7:0] rx_data,

    output logic       sclk,
    output logic       cs_n,
    output logic       mosi,
    input  logic       miso
);
  logic [2:0] cnt_tx, cnt_rx;
  logic [7:0] run_tx, run_rx, run_h, cnt_h; 
  logic [3:0] cnt_hh;

  always_ff@(posedge clk)begin
    if(!rst_n)begin
      cnt_h <= 8'd1;
      cnt_hh <= '0;
    end else begin
      if(done) begin
        cnt_h <= 8'd1;
      end else begin
        if (busy)begin
          cnt_h <= cnt_h + 1'b1;
        if(cnt_h == run_h)begin
          cnt_h <= 8'd1;
          cnt_hh <= cnt_hh + 1'b1;
        end
        end

      end
    end
  end

  always_ff@(posedge clk)begin
    if(!rst_n)begin
      busy <= '0;
      done <= '0;
      rx_data <= '0;
      sclk <= '0;
      cs_n <= 1'b1;
      mosi <= '0;
      run_tx <= '0;
      run_rx <= '0;
      run_h  <= '0;
      cnt_rx <= 3'd7;
      cnt_tx <= 3'd7;
    end else begin
      done <= '0;
      if(start && !busy)begin//accept a new value 
        mosi <= tx_data[cnt_tx];
        run_tx  <= tx_data;
        run_rx  <= '0;
        run_h   <= (|cfg_half_period)?cfg_half_period:8'd1;
        busy    <= 1'b1;
        cs_n    <= '0;
        done    <= '0;
        sclk    <= '0;
      end else if(busy)begin
        if((cnt_h == run_h) && sclk)begin
          mosi <= run_tx[cnt_tx-1];
          cnt_tx <= cnt_tx - 1'b1;
        end else if((cnt_h == run_h) && !sclk)begin
          run_rx[cnt_rx] <= miso;
          cnt_rx <= cnt_rx - 1'b1;
        end
        if(cnt_h == run_h)begin
          sclk    <= ~sclk;
        end
        if((cnt_hh == 15) && sclk && (cnt_h == run_h))begin
          done <= 1'b1;
          sclk <= '0;
          cs_n <= 1'b1;
          mosi <= '0;
          busy <= '0;
          rx_data <= run_rx;
      end
    end
  end
  end
endmodule
