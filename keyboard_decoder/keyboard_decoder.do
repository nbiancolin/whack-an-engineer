vlib work
vlog keyboard_decoder.v
vsim keyboard_decoder
log {/*}
add wave {/*}

force {clock} 0,1 5 ns -r 20 ns

force {reset} 0
force {pressed_temp} 0
force data_temp 00011010
run 40 ns

force {reset} 1
run 40 ns

force {reset} 0
force {pressed_temp} 1
run 40 ns

force {pressed_temp} 0
run 40 ns

force data_temp 11110000
run 40 ns

force data_temp 00011010
force {pressed_temp} 1
run 40 ns

force data_temp 11111111
run 40 ns