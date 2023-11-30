vlib work
vlog generateMoles.v 

vsim generateMoles

log {/*}
add wave {/*}

force {clock} 0 0, 1 10ns -r 20ns


force {reset} 1
force {enable} 0

run 40ns
force {reset} 0


force {enable} 1
run 40ns

force {enable} 0
run 100ns

force {enable} 1
run 100ns
