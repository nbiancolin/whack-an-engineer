vlib work 
vlog part2.v
vsim -L altera_mf_ver vgaHelper
#vsim -L work vgaHelper
log  /*
add wave {/*}

force {clk} 0 ns, 1 {1ns} -r 2ns

#RESET
force iResetn 1'b1;
force hhSelect 5'b0;
force hhState 4'b0;
force startGame 1'b0;
force endGame 1'b0;
run 4ns

#draw start screen
force iResetn 1'b0; 
run 50000ns;

#start game
force startGame 1'b1;
run 10 ns;
force startGame 1'b0;
run 50000ns;

#try and draw a hard hat
force hhSelect 5'b01000; #select 4th hat
force hhState 3'b010;
run 10ns;
force hhState 3'b000;
run 5000ns;
force hhSelect 5'b000;
run 5000ns;

force hhSelect 5'b00100; #select 3th hat
force hhState 3'b100;
run 10ns;
force hhState 3'b000;
run 5000ns;
force hhSelect 5'b00000;
run 5000ns;

force endGame 1'b1; #end game
run 10ns;
force endGame 1'b0;
run 50000ns;
