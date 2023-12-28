vlib work
vlog scoreKeeper.v

vsim scoreKeeper

log {/*}
add wave {/*}

force {clock} 0 0, 1 10ns -r 20ns

force {scoreReset} 1
run 40ns

force {scoreReset} 0

force {moleHit} 3'b001
run 100ns 
force {moleHit} 3'b010
run 100ns
force {moleHit} 3'b100
run 100ns

force {scoreReset} 1
run 40ns

force {scoreReset} 0
force {moleHit} 3'b001
run 100ns 
force {moleHit} 3'b010
run 100ns
force {moleHit} 3'b100
run 100ns