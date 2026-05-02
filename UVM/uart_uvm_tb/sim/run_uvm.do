transcript on

if {[file exists work]} {
    vdel -lib work -all
}

vlib work
vmap work work

vlog -sv -f filelist_uvm.f

vsim -voptargs=+acc work.top_tb +UVM_TESTNAME=uart_tx_basic_test

log -r /*
add wave -r /*
run -all
