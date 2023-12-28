vlib work
vlog countdownTimer.v

vsim countdownTimer

log {/*}
add wave {/*}

force {clock} 0 0, 1 10ns -r 20ns

force {scoreReset} 1
run 40ns  

force {scoreReset} 0
force {enableCountdown} 1
run 3000000000ns 