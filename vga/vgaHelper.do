vlib work 
vlog vgaHelper.v
vsim -L altera_mf_ver vgaHelper
#vsim -L work vgaHelper
log  /*
add wave {/*}

force {clk} 0 ns, 1 {1ns} -r 2ns

#RESET
force iResetn 1'b1;
force hhSelect 5'b00000;
force gameState 3'b000;
force moleHit 1'b0;
run 10ns;

#load splash screen
force iResetn 1'b0;
run 1000000ns;

#start game
force gameState <= 3'd2;
run 1000000ns;