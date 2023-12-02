module vga_handler(clock, reset, X_POS, Y_POS, X_OUT, Y_OUT, plot_en);
	input clock, reset;
	input [7:0] X_POS, Y_POS;
	output reg [7:0] X_OUT, Y_OUT;
	output plot_en;

	parameter X_MAX = 8'd160;
	parameter Y_MAX = 7'd120;

	datapath dp(clock, reset, X_POS, Y_POS, X_OUT, Y_OUT);
	ctrlpath cp(clock, reset, X_POS, Y_POS, X_OUT, Y_OUT);

endmodule

module ctrlpath(resetn, clock, ld_x, ld_y, ld_clr, ld_blk, colour, counter, counter_bl_x, counter_bl_y, plot_in, plot_out, done_t, state_curr, state_next);
	input resetn, clock, ld_x, ld_blk, plot_in;
	input [2:0] colour;
	input [3:0] counter;
	input [7:0] counter_bl_x;
	input [6:0] counter_bl_y;
	output reg ld_y, ld_clr, plot_out;
	output reg done_t;	
	output reg [6:0] state_curr, state_next;
	
	localparam 	S_WAIT		= 4'd0,
				S_LOAD_X	= 4'd1,
				S_LOAD_X_WAIT	= 4'd2,
				S_DRAW		= 4'd3,
				S_BLACK		= 4'd4,
				S_FIN		= 4'd5,
				S_FIN_2		= 4'd6,
				S_FIN_INTERMEDIATE 	= 4'd7,
				S_LOAD_Y	= 4'd8,
				S_LOAD_Y_WAIT	= 4'd9;

	// assign done_t = (state_curr == S_FIN) || (state_curr == S_WAIT) || (state_curr == S_FIN_2) || (state_curr == S_LOAD_X) || (state_curr == S_LOAD_X_WAIT);
	
	// state table and signal assignment
	always@(*)
	begin
		ld_y = 'b0;
		ld_clr = 'b0;
		plot_out = 'b0;
		
		case(state_curr)
			S_WAIT: begin
				done_t = 1'b0;
				plot_out = 1'b0;
				if (ld_blk == 1'b1)
					state_next = S_BLACK;
				else begin
					if (ld_x)
						state_next = S_LOAD_X;
					else
						state_next = S_WAIT;
				end
				/*(resetn == 1'b0) // active low reset
					state_next = S_WAIT;
				else // if load x, then load all
					state_next = S_LOAD_X; */
			end
			S_LOAD_X: begin
				done_t = 1'b0;
				/*
				plot_out = 1'b0;
				if (ld_blk == 1'b1) begin
					state_next = S_BLACK;
					// done_t = 1'b0;
				end
				if (resetn == 1'b0)
					state_next = S_LOAD_X; */
				if (plot_in == 1'b1)
					state_next = S_LOAD_Y;
				else if (plot_in == 1'b0)
					state_next = S_LOAD_X;
				//state_next = plot_in ? S_LOAD_WAIT : S_LOAD; // Loop in current state until value is input
			end
			S_LOAD_X_WAIT: begin
				// counter = 'b0;
				ld_y = 1'b0;
				if (plot_in == 1'b0) begin
					state_next = S_DRAW;
					done_t = 1'b0;
				end
				else if (plot_in == 1'b1)
					state_next = S_LOAD_X_WAIT;
			end
			S_LOAD_Y: begin
				ld_y = 1'b1;
				if (plot_in == 1'b0) begin
					state_next = S_DRAW;
				end else
					state_next = S_LOAD_Y;
				/*ld_y = 1'b1;
				state_next = S_LOAD_Y_WAIT; */
			end
			S_LOAD_Y_WAIT: state_next = S_LOAD_X_WAIT;
			S_DRAW: begin
				plot_out = 1'b1;
				done_t = 1'b0;
				ld_y = 1'b0;
				if (counter != 4'b1111) begin // loop until finished
					state_next = S_DRAW;
				end
				else begin // if we've finished
					// done_t = 1'b1;
					state_next = S_FIN;
				end
			end
			S_BLACK: begin
				plot_out = 1'b1;
				if (counter_bl_x != 8'd160 && counter_bl_y != 7'd120)
					state_next = S_BLACK; // loop until finished
				else begin
					state_next = S_FIN;
					//done_t = 1'b1;
				end
			end
			S_FIN: begin
				state_next = S_WAIT;
				done_t = 1'b1;
				plot_out = 1'b0;
			end
			S_FIN_INTERMEDIATE: begin
				state_next = S_FIN_2;
				//done_t = 1'b1;
           	plot_out = 1'b0;
			end
			S_FIN_2: begin
				done_t = 1'b1;
				plot_out = 1'b0;
				state_next = S_WAIT;
			end
			default: begin 
				state_next = S_LOAD_X;
				plot_out = 1'b0;
			end
		endcase
	end

	// current_state registers
   always@(posedge clock)
   begin : state_FFs
       if (!resetn) begin // active low reset
           state_curr <= S_LOAD_X;
		end
       else
           state_curr <= state_next;
   end // state_FFS

	
endmodule


module cursor_handler
	(
		CLOCK_50,						//	On Board 50 MHz
		// Your inputs and outputs here
		resetn,							// On Board Keys
		writeEn,
		// The ports below are for the VGA output.  Do not change.
		VGA_CLK,   						//	VGA Clock
		VGA_HS,							//	VGA H_SYNC
		VGA_VS,							//	VGA V_SYNC
		VGA_BLANK_N,						//	VGA BLANK
		VGA_SYNC_N,						//	VGA SYNC
		VGA_R,   						//	VGA Red[9:0]
		VGA_G,	 						//	VGA Green[9:0]
		VGA_B,   						//	VGA Blue[9:0]
		X_POS,
		Y_POS
	);

	input	CLOCK_50;				//	50 MHz
	input resetn, writeEn;
	input [7:0] X_POS, Y_POS;
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
	
	// Create the colour, x, y and writeEn wires that are inputs to the controller.

	wire [2:0] colour;
	wire [7:0] x;
	wire [6:0] y;

	// Create an Instance of a VGA controller - there can be only one!
	// Define the number of colours as well as the initial background
	// image file (.MIF) for the controller.
	vga_adapter VGA(
			.resetn(resetn),
			.clock(CLOCK_50),
			.colour(colour),
			.x(x),
			.y(y),
			.plot(writeEn),
			/* Signals for the DAC to drive the monitor. */
			.VGA_R(VGA_R),
			.VGA_G(VGA_G),
			.VGA_B(VGA_B),
			.VGA_HS(VGA_HS),
			.VGA_VS(VGA_VS),
			.VGA_BLANK(VGA_BLANK_N),
			.VGA_SYNC(VGA_SYNC_N),
			.VGA_CLK(VGA_CLK));
		defparam VGA.RESOLUTION = "160x120";
		defparam VGA.MONOCHROME = "FALSE";
		defparam VGA.BITS_PER_COLOUR_CHANNEL = 1;
		defparam VGA.BACKGROUND_IMAGE = "black.mif";
			
	// Put your code here. Your code should produce signals x,y,colour and writeEn
	// for the VGA controller, in addition to any other functionality your design may require
	assign x = X_POS;
	assign y = Y_POS;
	assign colour = 3'b111;
	// vga_handler vh(resetn, ~KEY[1], KEY[2], SW[9:7], ~KEY[3], SW[6:0], CLOCK_50, X_POS, Y_POS, writeEn, 1'b1);
	
endmodule
