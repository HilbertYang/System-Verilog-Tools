class uart_tx_basic_sequence extends uvm_sequence #(uart_item);

  `uvm_object_utils(uart_tx_basic_sequence)

  function new(string name = "uart_tx_basic_sequence");
    super.new(name);
  endfunction

  task body();
    bit [7:0] data_list[$] = '{8'h55, 8'ha5, 8'h00, 8'hff, 8'h3c, 8'hc3, 8'h12, 8'hed};

    foreach (data_list[i]) begin
      uart_item item;

      item = uart_item::type_id::create($sformatf("item_%0d", i));
      start_item(item);
      item.data = data_list[i];
      finish_item(item);
    end
  endtask

endclass
