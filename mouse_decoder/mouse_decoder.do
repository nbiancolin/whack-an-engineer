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
run 40 ns

force state_d 10
run 40 ns