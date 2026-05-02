class uart_tx_basic_test extends uvm_test;

  `uvm_component_utils(uart_tx_basic_test)

  localparam int NUM_ITEMS = 8;

  uart_env env;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    env = uart_env::type_id::create("env", this);
  endfunction

  task run_phase(uvm_phase phase);
    uart_tx_basic_sequence seq;

    phase.raise_objection(this);

    seq = uart_tx_basic_sequence::type_id::create("seq");
    seq.start(env.agent.sequencer);

    fork
      begin
        wait (env.scoreboard.compare_count == NUM_ITEMS);
      end
      begin
        repeat (20000) @(posedge env.agent.driver.vif.clk);
        `uvm_fatal("TIMEOUT", "timed out waiting for scoreboard comparisons")
      end
    join_any
    disable fork;

    phase.drop_objection(this);
  endtask

endclass
