vlib work

vlog mouse_decoder.v

vsim mouse_decoder

log {/*}

add wave {/*}

force {clock} 0,1 5 ns -r 20 ns

force {resetn} 0
force {command_conf} 0
run 40 ns

force {resetn} 1
run 40 ns

force {resetn} 0
force {command_conf} 1
run 20 ns

force {command_conf} 0
force {received_data_en} 1
force received_data 00111000
run 20 ns

force received_data 00011111
run 20 ns

force received_data 00000011
run 20 ns