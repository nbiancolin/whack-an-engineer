vlib work
vlog main.v

vsim mainDataPath

log {/*}
add wave {/*}


force {clock} 0 0, 1 10ns -r 20ns

force {reset} 1
run 100ns
force {reset} 0
run 100ns

force {startGame} 1
run 1000ns
force {startGame} 0

force {userGameInput} 3'b001
run 20ns
force {userGameInput} 3'b000
run 30ns

force {userGameInput} 3'b010
run 20ns
force {userGameInput} 3'b000
run 30ns

force {userGameInput} 3'b100
run 20ns
force {userGameInput} 3'b000
run 30ns

force {userGameInput} 3'b101
run 20ns
force {userGameInput} 3'b000
run 20ns
force {userGameInput} 3'b001
run 20ns
force {userGameInput} 3'b000
run 30ns

force {userGameInput} 3'b010
run 20ns
force {userGameInput} 3'b000
run 30ns

force {userGameInput} 3'b100
run 20ns
force {userGameInput} 3'b000
run 30ns

force {userGameInput} 3'b101
run 20ns
force {userGameInput} 3'b000
run 20ns
force {userGameInput} 3'b001
run 20ns
force {userGameInput} 3'b000
run 30ns

force {userGameInput} 3'b010
run 20ns
force {userGameInput} 3'b000
run 30ns

force {userGameInput} 3'b100
run 20ns
force {userGameInput} 3'b000
run 30ns

force {userGameInput} 3'b101
run 20ns
force {userGameInput} 3'b000
run 20ns
force {userGameInput} 3'b001
run 20ns
force {userGameInput} 3'b000
run 30ns

force {userGameInput} 3'b010
run 20ns
force {userGameInput} 3'b000
run 30ns

force {userGameInput} 3'b100
run 20ns
force {userGameInput} 3'b000
run 30ns

force {userGameInput} 3'b101
run 20ns
force {userGameInput} 3'b000
run 20ns
force {userGameInput} 3'b001
run 20ns
force {userGameInput} 3'b000
run 30ns

force {userGameInput} 3'b010
run 20ns
force {userGameInput} 3'b000
run 30ns

force {userGameInput} 3'b100
run 20ns
force {userGameInput} 3'b000
run 30ns

force {userGameInput} 3'b101
run 20ns
force {userGameInput} 3'b000
run 20ns
force {userGameInput} 3'b001
run 20ns
force {userGameInput} 3'b000
run 30ns

force {userGameInput} 3'b010
run 20ns
force {userGameInput} 3'b000
run 30ns

force {userGameInput} 3'b100
run 20ns
force {userGameInput} 3'b000
run 30ns

force {userGameInput} 3'b101
run 20ns
force {userGameInput} 3'b000
run 20ns
force {userGameInput} 3'b001
run 20ns
force {userGameInput} 3'b000
run 30ns

force {userGameInput} 3'b010
run 20ns
force {userGameInput} 3'b000
run 30ns

force {userGameInput} 3'b100
run 20ns
force {userGameInput} 3'b000
run 30ns

force {userGameInput} 3'b101
run 20ns
force {userGameInput} 3'b000
run 20ns

force {userGameInput} 3'b100
run 20ns
force {userGameInput} 3'b000
run 30ns

force {userGameInput} 3'b101
run 20ns
force {userGameInput} 3'b000
run 20ns
force {userGameInput} 3'b100
run 20ns
force {userGameInput} 3'b000
run 30ns

force {userGameInput} 3'b101
run 20ns
force {userGameInput} 3'b000
run 20ns
force {userGameInput} 3'b100
run 20ns
force {userGameInput} 3'b000
run 30ns

force {userGameInput} 3'b101
run 20ns
force {userGameInput} 3'b000
run 20ns


run 70us

run 150ns

force {reset} 1
run 20ns
force {reset} 0
run 10ns
force {startGame} 1

run 10us

