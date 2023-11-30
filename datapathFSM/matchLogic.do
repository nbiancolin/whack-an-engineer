vlib work
vlog matchLogic.v

vsim matchLogic

log {/*}
add wave {/*}

force {clock} 0 0, 1 10ns -r 20ns

force {molesGenerated} 5'b10101
force {hit} 3'b001
run 100ns 


force {molesGenerated} 5'b01010
force {hit} 3'b010
run 100ns

force {molesGenerated} 5'b10000
force {hit} 3'b000
run 100ns

force {molesGenerated} 5'b10000
force {hit} 3'b010
run 100ns