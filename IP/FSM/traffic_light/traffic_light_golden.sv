module traffic_light #(
    parameter int GREEN_TIME  = 4,
    parameter int YELLOW_TIME = 2
)(
    input  logic       clk,
    input  logic       rst_n,
    output logic [1:0] ns_light,
    output logic [1:0] ew_light
);
    localparam logic [1:0] RED    = 2'b00;
    localparam logic [1:0] YELLOW = 2'b01;
    localparam logic [1:0] GREEN  = 2'b10;

    typedef enum logic [1:0] {NS_GREEN, NS_YELLOW, EW_GREEN, EW_YELLOW} state_t;
    state_t curr, next;

    localparam int CNT_W = $clog2(GREEN_TIME > YELLOW_TIME ? GREEN_TIME : YELLOW_TIME) + 1;
    logic [CNT_W-1:0] cnt;

    wire green_done  = (cnt == CNT_W'(GREEN_TIME  - 1));
    wire yellow_done = (cnt == CNT_W'(YELLOW_TIME - 1));

    // counter
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)        cnt <= '0;
        else if (curr != next) cnt <= '0;
        else               cnt <= cnt + 1'b1;
    end

    // state register
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) curr <= NS_GREEN;
        else        curr <= next;
    end

    // next-state logic
    always_comb begin
        case (curr)
            NS_GREEN:  if (green_done)  next = NS_YELLOW; else next = NS_GREEN;
            NS_YELLOW: if (yellow_done) next = EW_GREEN;  else next = NS_YELLOW;
            EW_GREEN:  if (green_done)  next = EW_YELLOW; else next = EW_GREEN;
            EW_YELLOW: if (yellow_done) next = NS_GREEN;  else next = EW_YELLOW;
            default:   next = NS_GREEN;
        endcase
    end

    // Moore outputs
    always_comb begin
        case (curr)
            NS_GREEN:  begin ns_light = GREEN;  ew_light = RED;    end
            NS_YELLOW: begin ns_light = YELLOW; ew_light = RED;    end
            EW_GREEN:  begin ns_light = RED;    ew_light = GREEN;  end
            EW_YELLOW: begin ns_light = RED;    ew_light = YELLOW; end
            default:   begin ns_light = RED;    ew_light = RED;    end
        endcase
    end

endmodule
