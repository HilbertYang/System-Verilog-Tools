class uart_driver extends uvm_driver #(uart_item);

  `uvm_component_utils(uart_driver)

  virtual uart_if vif;
  uvm_analysis_port #(uart_item) expected_ap;

  function new(string name, uvm_component parent);
    super.new(name, parent);
    expected_ap = new("expected_ap", this);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    if (!uvm_config_db #(virtual uart_if)::get(this, "", "vif", vif)) begin
      `uvm_fatal("NOVIF", "uart_driver failed to get virtual interface")
    end
  endfunction

  task run_phase(uvm_phase phase);
    uart_item item;

    vif.tx_valid <= 1'b0;
    vif.tx_data  <= '0;

    wait (vif.rst_n);

    forever begin
      seq_item_port.get_next_item(item);
      drive_item(item);
      seq_item_port.item_done();
    end
  endtask

  task drive_item(uart_item item);
    uart_item expected;

    wait (vif.tx_ready);

    @(posedge vif.clk iff vif.baud_tick);
    @(negedge vif.clk);
    vif.tx_data  <= item.data;
    vif.tx_valid <= 1'b1;

    @(negedge vif.clk);
    vif.tx_valid <= 1'b0;

    expected = uart_item::type_id::create("expected");
    expected.data = item.data;
    expected_ap.write(expected);

    `uvm_info("DRV", $sformatf("drove data=0x%02h", item.data), UVM_MEDIUM)
  endtask

endclass
