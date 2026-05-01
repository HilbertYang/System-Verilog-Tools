transcript on

if {[file exists work]} {
    vdel -lib work -all
}

vlib work
vmap work work

vlog -sv -f filelist_rx.f

vsim -voptargs=+acc work.tb_uart_rx

add wave -r /*
run -all
