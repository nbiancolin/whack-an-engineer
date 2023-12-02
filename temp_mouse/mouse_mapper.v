module mouse_mapper(KEY, SW, CLOCK_50, PS2_CLK, PS2_DAT, LEDR, HEX3, HEX2, HEX1, HEX0, VGA_CLK, VGA_HS, VGA_VS, VGA_BLANK_N, VGA_SYNC_N, VGA_R, VGA_G, VGA_B);
	input [3:0] KEY;
	input [9:0] SW;
	input CLOCK_50;
	inout PS2_CLK, PS2_DAT;
	output [9:0] LEDR;
	output [6:0] HEX3, HEX2, HEX1, HEX0;

	output VGA_CLK, VGA_HS, VGA_VS, VGA_BLANK_N, VGA_SYNC_N;
	output [7:0] VGA_R, VGA_G, VGA_B;

	wire leftclick;
	wire [8:0] x, y;
	wire [1:0] cState;
	
	mouse(KEY[0], SW[0], CLOCK_50, PS2_CLK, PS2_DAT, LEDR[0], x, y, LEDR[9:8]);
	hex_decoder h0(x[3:0], HEX0);
	hex_decoder h1(x[7:4], HEX1);
	hex_decoder h2(y[3:0], HEX2);
	hex_decoder h3(y[7:4], HEX3);

	cursor_handler ch(CLOCK_50, ~KEY[0], SW[0], VGA_CLK, VGA_HS, VGA_VS, VGA_BLANK_N, VGA_SYNC_N, VGA_R, VGA_G, VGA_B, x, y);
	
endmodule

module hex_decoder(c, display); // from lab2
	input [3:0] c;
	output [6:0] display;
	
	assign display[0] = ~((~c[3] & ~c[2] & ~c[1] & ~c[0]) | (~c[3] & ~c[2] & c[1] & ~c[0]) | (~c[3] & ~c[2] & c[1] & c[0]) | (~c[3] & c[2] & ~c[1] & c[0]) | (~c[3] & c[2] & c[1] & ~c[0]) | (~c[3] & c[2] & c[1] & c[0]) | (c[3] & ~c[2] & ~c[1] & ~c[0]) | (c[3] & ~c[2] & ~c[1] & c[0]) | (c[3] & ~c[2] & c[1] & ~c[0]) | (c[3] & c[2] & ~c[1] & ~c[0]) | (c[3] & c[2] & c[1] & ~c[0]) | (c[3] & c[2] & c[1] & c[0]));
	
	assign display[1] = ~((~c[3] & ~c[2] & ~c[1] & ~c[0]) | (~c[3] & ~c[2] & ~c[1] & c[0]) | (~c[3] & ~c[2] & c[1] & ~c[0]) | (~c[3] & ~c[2] & c[1] & c[0]) | (~c[3] & c[2] & ~c[1] & ~c[0]) | (~c[3] & c[2] & c[1] & c[0]) | (c[3] & ~c[2] & ~c[1] & ~c[0]) | (c[3] & ~c[2] & ~c[1] & c[0]) | (c[3] & ~c[2] & c[1] & ~c[0]) | (c[3] & c[2] & ~c[1] & c[0]));
	
	assign display[2] = ~((~c[3] & ~c[2] & ~c[1] & ~c[0]) | (~c[3] & ~c[2] & ~c[1] & c[0]) | (~c[3] & ~c[2] & c[1] & c[0]) | (~c[3] & c[2] & ~c[1] & ~c[0]) | (~c[3] & c[2] & ~c[1] & c[0]) | (~c[3] & c[2] & c[1] & ~c[0]) | (~c[3] & c[2] & c[1] & c[0]) | (c[3] & ~c[2] & ~c[1] & ~c[0]) | (c[3] & ~c[2] & ~c[1] & c[0]) | (c[3] & ~c[2] & c[1] & ~c[0]) | (c[3] & ~c[2] & c[1] & c[0]) | (c[3] & c[2] & ~c[1] & c[0]));
	
	assign display[3] = ~((~c[3] & ~c[2] & ~c[1] & ~c[0]) | (~c[3] & ~c[2] & c[1] & ~c[0]) | (~c[3] & ~c[2] & c[1] & c[0]) | (~c[3] & c[2] & c[1] & ~c[0]) | (~c[3] & c[2] & ~c[1] & c[0]) | (~c[3] & c[2] & c[1] & ~c[0]) | (c[3] & ~c[2] & ~c[1] & ~c[0]) | (c[3] & ~c[2] & ~c[1] & c[0]) | (c[3] & ~c[2] & c[1] & c[0]) | (c[3] & c[2] & ~c[1] & ~c[0]) | (c[3] & c[2] & ~c[1] & c[0]) | (c[3] & c[2] & c[1] & ~c[0]));
	
	assign display[4] = ~((~c[3] & ~c[2] & ~c[1] & ~c[0]) | (~c[3] & ~c[2] & c[1] & ~c[0]) | (~c[3] & c[2] & c[1] & ~c[0]) | (c[3] & ~c[2] & ~c[1] & ~c[0]) | (c[3] & ~c[2] & c[1] & ~c[0]) | (c[3] & ~c[2] & c[1] & c[0]) | (c[3] & c[2] & ~c[1] & ~c[0]) | (c[3] & c[2] & ~c[1] & c[0]) | (c[3] & c[2] & c[1] & ~c[0]) | (c[3] & c[2] & c[1] & c[0]));
	
	assign display[5] = ~((~c[3] & ~c[2] & ~c[1] & ~c[0]) | (~c[3] & c[2] & ~c[1] & ~c[0]) | (~c[3] & c[2] & ~c[1] & c[0]) | (~c[3] & c[2] & c[1] & ~c[0]) | (c[3] & ~c[2] & ~c[1] & ~c[0]) | (c[3] & ~c[2] & ~c[1] & c[0]) | (c[3] & ~c[2] & c[1] & ~c[0]) | (c[3] & ~c[2] & c[1] & c[0]) | (c[3] & c[2] & ~c[1] & ~c[0]) | (c[3] & c[2] & c[1] & ~c[0]) | (c[3] & c[2] & c[1] & c[0]));
	
	assign display[6] = ~((~c[3] & ~c[2] & c[1] & ~c[0]) | (~c[3] & ~c[2] & c[1] & c[0]) | (~c[3] & c[2] & ~c[1] & ~c[0]) | (~c[3] & c[2] & ~c[1] & c[0]) | (~c[3] & c[2] & c[1] & ~c[0]) | (c[3] & ~c[2] & ~c[1] & ~c[0]) | (c[3] & ~c[2] & ~c[1] & c[0]) | (c[3] & ~c[2] & c[1] & ~c[0]) | (c[3] & ~c[2] & c[1] & c[0]) | (c[3] & c[2] & ~c[1] & c[0]) | (c[3] & c[2] & c[1] & ~c[0]) | (c[3] & c[2] & c[1] & c[0]));
	
endmodule
