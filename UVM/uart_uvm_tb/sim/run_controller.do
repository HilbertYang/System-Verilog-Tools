transcript on

if {[file exists work]} {
    vdel -lib work -all
}

vlib work
vmap work work

vlog -sv -f filelist_controller.f

vsim -voptargs=+acc work.tb_uart_controller

log -r /*
add wave -r /*
run -all
