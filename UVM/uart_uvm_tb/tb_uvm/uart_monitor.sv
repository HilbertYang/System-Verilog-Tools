class uart_monitor extends uvm_monitor;

  `uvm_component_utils(uart_monitor)

  virtual uart_if vif;
  uvm_analysis_port #(uart_item) actual_ap;

  function new(string name, uvm_component parent);
    super.new(name, parent);
    actual_ap = new("actual_ap", this);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    if (!uvm_config_db #(virtual uart_if)::get(this, "", "vif", vif)) begin
      `uvm_fatal("NOVIF", "uart_monitor failed to get virtual interface")
    end
  endfunction

  task run_phase(uvm_phase phase);
    wait (vif.rst_n);

    forever begin
      collect_frame();
    end
  endtask

  task collect_frame();
    uart_item item;
    bit [7:0] data;

    @(negedge vif.tx);

    if (!vif.rst_n) begin
      return;
    end

    wait_baud_and_sample();

    for (int i = 0; i < 8; i++) begin
      data[i] = vif.tx;
      wait_baud_and_sample();
    end

    if (vif.tx !== 1'b1) begin
      `uvm_error("MON", $sformatf("stop bit should be 1, got %0b", vif.tx))
    end

    item = uart_item::type_id::create("actual");
    item.data = data;
    actual_ap.write(item);

    `uvm_info("MON", $sformatf("observed data=0x%02h", data), UVM_MEDIUM)
  endtask

  task wait_baud_and_sample();
    @(posedge vif.clk iff vif.baud_tick);
    @(negedge vif.clk);
  endtask

endclass
