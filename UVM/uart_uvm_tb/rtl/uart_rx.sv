module uart_rx #(
  parameter int OVERSAMPLE = 16
)(
  input  logic       clk,
  input  logic       rst_n,

  input  logic       sample_tick,
  input  logic       rx,

  output logic       rx_valid,
  output logic [7:0] rx_data
);

  typedef enum logic [1:0] {
    IDLE,
    START,
    DATA,
    STOP
  } state_t;

  state_t     state;
  logic [2:0] bit_idx;
  logic [$clog2(OVERSAMPLE)-1:0] sample_cnt;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      state      <= IDLE;
      bit_idx    <= '0;
      sample_cnt <= '0;
      rx_valid   <= 1'b0;
      rx_data    <= '0;
    end else begin
      rx_valid <= 1'b0;

      unique case (state)
        IDLE: begin
          bit_idx    <= '0;
          sample_cnt <= '0;

          if (!rx) begin
            state <= START;
          end
        end

        START: begin
          if (sample_tick) begin
            if (sample_cnt == (OVERSAMPLE / 2) - 1) begin
              sample_cnt <= '0;

              if (!rx) begin
                state   <= DATA;
                bit_idx <= '0;
              end else begin
                state <= IDLE;
              end
            end else begin
              sample_cnt <= sample_cnt + 1'b1;
            end
          end
        end

        DATA: begin
          if (sample_tick) begin
            if (sample_cnt == OVERSAMPLE - 1) begin
              sample_cnt      <= '0;
              rx_data[bit_idx] <= rx;

              if (bit_idx == 3'd7) begin
                state <= STOP;
              end else begin
                bit_idx <= bit_idx + 3'd1;
              end
            end else begin
              sample_cnt <= sample_cnt + 1'b1;
            end
          end
        end

        STOP: begin
          if (sample_tick) begin
            if (sample_cnt == OVERSAMPLE - 1) begin
              sample_cnt <= '0;

              if (rx) begin
                rx_valid <= 1'b1;
              end

              state <= IDLE;
            end else begin
              sample_cnt <= sample_cnt + 1'b1;
            end
          end
        end

        default: begin
          state      <= IDLE;
          sample_cnt <= '0;
        end
      endcase
    end
  end

endmodule
