module uart_tx (
  input  logic       clk,
  input  logic       rst_n,

  input  logic       baud_tick,
  input  logic       tx_valid,

  output logic       tx_ready,
  input  logic [7:0] tx_data,
  output logic       tx
);

  typedef enum logic [1:0] {
    IDLE,
    START,
    DATA,
    STOP
  } state_t;

  state_t     state;
  logic [7:0] data_reg;
  logic [2:0] bit_idx;

  assign tx_ready = (state == IDLE);

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      state    <= IDLE;
      data_reg <= '0;
      bit_idx  <= '0;
      tx       <= 1'b1;
    end else begin
      unique case (state)
        IDLE: begin
          tx      <= 1'b1;
          bit_idx <= '0;

          if (tx_valid) begin
            data_reg <= tx_data;
            state    <= START;
            tx       <= 1'b0;
          end
        end

        START: begin
          if (baud_tick) begin
            state   <= DATA;
            bit_idx <= '0;
            tx      <= data_reg[0];
          end
        end

        DATA: begin
          if (baud_tick) begin
            if (bit_idx == 3'd7) begin
              state <= STOP;
              tx    <= 1'b1;
            end else begin
              bit_idx <= bit_idx + 3'd1;
              tx      <= data_reg[bit_idx + 3'd1];
            end
          end
        end

        STOP: begin
          if (baud_tick) begin
            state <= IDLE;
            tx    <= 1'b1;
          end
        end

        default: begin
          state <= IDLE;
          tx    <= 1'b1;
        end
      endcase
    end
  end

endmodule
