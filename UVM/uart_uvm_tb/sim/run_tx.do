transcript on

if {[file exists work]} {
    vdel -lib work -all
}

vlib work
vmap work work

vlog -sv -f filelist_tx.f

vsim -voptargs=+acc work.tb_uart_tx

log -r /*
add wave -r /*
run -all
