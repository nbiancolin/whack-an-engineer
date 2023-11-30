module rng_mapper(CLOCK50, SW, LEDR, KEY);
	input CLOCK50;
	input [9:0] SW;
	input [3:0] KEY;
	output [9:0] LEDR;
	
	pseudo_rng(CLOCK50, ~KEY[3], ~KEY[0], LEDR[4:0]);
	
endmodule
