vlib work

vlog pseudo_rng.v

vsim pseudo_rng

log {/*}

add wave {/*}

force {clock} 0,1 5 ns -r 20 ns

force {reset} 0
force {generateEn} 0
run 40 ns

force {generateEn} 0,1 5 ns -r 10 ns
run 400 ns