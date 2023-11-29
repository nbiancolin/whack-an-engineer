module handler(CLOCK50, PS2_CLK, PS2_DAT, MOUSE_MODE, X_POS, Y_POS, MOUSE_CLICK, KEY_PRESSED, resetn);
	input CLOCK50;
	inout PS2_CLK, PS2_DAT;
	input MOUSE_MODE;
	input resetn;
	output [7:0] X_POS, Y_POS;
	output MOUSE_CLICK;
	output [7:0] KEY_PRESSED;
	
	wire received_en;
	parameter [7:0] X_SIZE = 'd160, Y_SIZE = 'd120;
	
	mouse_decoder md(CLOCK50, PS2_CLK, PS2_DAT, resetn, MOUSE_CLICK, X_POS, Y_POS, received_en);
	keyboard_decoder kd(PS2_CLK, PS2_DAT, CLOCK50, resetn, KEY_PRESSED, received_en);
endmodule

module peripheral_handler(CLOCK50, PS2_CLK, PS2_DAT, KEY, LEDR, VGA_CLK, VGA_HS, VGA_VS, VGA_BLANK_N, VGA_SYNC_N, VGA_R, VGA_G, VGA_B);
	// for physical debugging and display
	input			CLOCK50;				//	50 MHz
	inout PS2_CLK, PS2_DAT;
	input	[3:0]	KEY;
	output [9:0] LEDR;
	// Declare your inputs and outputs here
	// Do not change the following outputs
	output			VGA_CLK;   				//	VGA Clock
	output			VGA_HS;					//	VGA H_SYNC
	output			VGA_VS;					//	VGA V_SYNC
	output			VGA_BLANK_N;				//	VGA BLANK
	output			VGA_SYNC_N;				//	VGA SYNC
	output	[7:0]	VGA_R;   				//	VGA Red[7:0] Changed from 10 to 8-bit DAC
	output	[7:0]	VGA_G;	 				//	VGA Green[7:0]
	output	[7:0]	VGA_B;   				//	VGA Blue[7:0]
	
	wire MOUSE_MODE;
	wire [7:0] X_POS, Y_POS;
	wire MOUSE_CLICK;
	wire [7:0] KEY_PRESSED;
	wire resetn = KEY[0];
	assign LEDR[0] = resetn; // for my sanity

	cursor_handler ch(CLOCK50, KEY, VGA_CLK, VGA_HS, VGA_HS, VGA_VS, VGA_BLANK_N, VGA_SYNC_N, VGA_R, VGA_G, VGA_B);
	handler ph(CLOCK50, PS2_CLK, PS2_DAT, MOUSE_MODE, X_POS, Y_POS, MOUSE_CLICK, KEY_PRESSED, resetn, X_POS, Y_POS);
	
endmodule
