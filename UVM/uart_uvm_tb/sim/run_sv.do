transcript on

if {[file exists work]} {
    vdel -lib work -all
}

vlib work
vmap work work

vlog -sv -f filelist_sv.f

vsim -voptargs=+acc work.tb_uart_baud_gen

add wave -r /*
run -all
