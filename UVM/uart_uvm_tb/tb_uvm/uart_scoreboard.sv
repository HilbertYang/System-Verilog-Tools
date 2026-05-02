`uvm_analysis_imp_decl(_expected)
`uvm_analysis_imp_decl(_actual)

class uart_scoreboard extends uvm_scoreboard;

  `uvm_component_utils(uart_scoreboard)

  uvm_analysis_imp_expected #(uart_item, uart_scoreboard) expected_imp;
  uvm_analysis_imp_actual #(uart_item, uart_scoreboard) actual_imp;

  uart_item expected_q[$];
  int unsigned compare_count;

  function new(string name, uvm_component parent);
    super.new(name, parent);
    expected_imp = new("expected_imp", this);
    actual_imp   = new("actual_imp", this);
  endfunction

  function void write_expected(uart_item item);
    uart_item item_copy;

    item_copy = uart_item::type_id::create("expected_copy");
    item_copy.copy(item);
    expected_q.push_back(item_copy);
  endfunction

  function void write_actual(uart_item item);
    uart_item expected;

    if (expected_q.size() == 0) begin
      `uvm_error("SCB", $sformatf("unexpected actual data=0x%02h", item.data))
      return;
    end

    expected = expected_q.pop_front();

    if (item.data !== expected.data) begin
      `uvm_error("SCB", $sformatf("data mismatch: expected=0x%02h actual=0x%02h", expected.data, item.data))
    end else begin
      compare_count++;
      `uvm_info("SCB", $sformatf("compare passed data=0x%02h count=%0d", item.data, compare_count), UVM_LOW)
    end
  endfunction

  function void check_phase(uvm_phase phase);
    super.check_phase(phase);

    if (expected_q.size() != 0) begin
      `uvm_error("SCB", $sformatf("%0d expected item(s) were not observed", expected_q.size()))
    end
  endfunction

endclass
