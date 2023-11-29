module pseudo_rng(clock, press_generate, address, output_data, reset);
	// pseudo rng relying on fast clocks
	input clock, press_generate;
	input [3:0] address;
	output wire [3:0] output_data;
	
	wire [3:0] input_data;
	
	rng_divider rd(clock, press_generate, input_data);
	bram br(address, clock, input_data, press_generate, output_data);
	
endmodule

module rng_divider(clock, enable, rand);
	input clock, enable;
	output reg [3:0] rand;
	
	parameter uppermax = $clog2(50000000);
	reg [uppermax + 2:0] counter;
	
	always@(posedge clock) begin
		if (enable) begin
			rand <= counter % 6;
			counter <= counter + 1;
		end
		else begin
			if (counter < 50000000 && counter >= 0)
				counter <= counter + 1;
			else
				counter <= 'b0;
		end
	end
endmodule

module rng_mapper(CLOCK50, KEY, SW, LEDR, HEX0);
	// for physical debugging
	input CLOCK50;
	input [3:0] KEY;
	input [9:0] SW;
	output [9:0] LEDR;
	output [6:0] HEX0;
	
	pseudo_rng pr(CLOCK50, ~KEY[0], SW[3:0], HEX0, ~KEY[3]);
endmodule
