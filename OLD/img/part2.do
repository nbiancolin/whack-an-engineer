vlib work 
vlog part2.v
vsim -L work part2
log  /*
add wave {/*}

force {iClock} 0 ns, 1 {1ns} -r 4ns

#RESET
force iResetn 1'b0;
force iPlotBox 1'b0;
force iLoadX 1'b0;
force iBlack 1'b0;
run 10ns

force iResetn 1'b1;
run 50ns;



#start game

force iBlack 1'b1;
run 10 ns;

#should draw entire screen
force iBlack 1'b0;
run 100000ns;

force iLoadX 1'b1;
run 10ns;

force iLoadX 1'b0;
run 150ns;


force iResetn 1'b0;
run 10ns;
force iResetn 1'b1;
run 100ns;