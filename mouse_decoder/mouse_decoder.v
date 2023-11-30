`timescale 1ns / 1ns // `timescale time_unit/time_precision

module mouse_decoder #(parameter X_MAX = 160, Y_MAX = 120) (clock, PS2_CLK, PS2_DAT, resetn, mouse_click, x_pos, y_pos, received_en);
	input clock;
	inout PS2_CLK, PS2_DAT;
	input resetn;
	output reg mouse_click;
	output reg [7:0] x_pos, y_pos;
	output received_en;
	
	// registers
	reg [7:0] command;
	reg command_send;
	wire [7:0] received_data;
	wire received_data_en;
	reg x_sign, y_sign;
	reg [1:0] state_d;
	
	assign received_en = received_data_en;
	wire command_conf;
	wire command_err;
	reg [4:0] curr_state, next_state;
	
	localparam	S_RESET			= 4'd0,
				S_IDLE			= 4'd1,
				S_ASSERT		= 4'd2,
				S_ASSERT_WAIT	= 4'd3,
				S_RESET_WAIT	= 4'd4,
				S_GETBITS		= 4'd5,
				S_GETX			= 4'd6,
				S_GETY			= 4'd7;
	
	always@(*) begin
		case(curr_state)
			S_RESET: begin
				command = 8'hFF;
				command_send = 'b1;
				next_state = S_RESET_WAIT;
			end
			S_RESET_WAIT: begin
				command_send = 'b0;
				// next_state = command_conf ? S_ASSERT : S_RESET_WAIT;
				next_state = S_ASSERT;
			end
			S_ASSERT: begin
				command = 8'hF4;
				command_send = 'b1;
				next_state = S_ASSERT_WAIT;
			end
			S_ASSERT_WAIT: begin
				command_send = 'b0;
				// next_state = command_conf ? S_IDLE : S_ASSERT_WAIT;
				next_state = S_GETBITS;
			end
			S_GETBITS: begin
				next_state = S_GETX;
			end
			S_GETX: begin
				next_state = S_GETY;
			end
			S_GETY: begin
				next_state = S_IDLE;
			end
			S_IDLE: begin
				next_state = received_data_en ? S_GETBITS : S_IDLE;
			end
			default: next_state = S_IDLE;
		endcase
	end
	
	always@(posedge clock) begin
		if (resetn) begin
			curr_state <= S_RESET;
		end 
		else
			curr_state <= next_state;
	end
	
	always@(posedge clock) begin
		if (resetn) begin
			state_d <= 'b0;
			x_pos <= 'b0;
			y_pos <= 'b0;
			x_sign <= 'b0;
			y_sign <= 'b0;
		end
		else begin
			if (received_data_en) begin
				case(state_d)
					2'b00: begin
						x_sign <= received_data[4];
						y_sign <= received_data[5];
						// overflow bits needed
						x_pos <= x_pos;
						y_pos <= y_pos;
						mouse_click <= received_data[0];
					end
					2'b01: begin
						if (x_sign == 1'b1)
							x_pos <= x_pos + received_data;
						else
							x_pos <= x_pos - received_data;
					end
					2'b10: begin
						if (y_sign == 1'b1)
							y_pos <= y_pos + received_data;
						else
							y_pos <= y_pos - received_data;
					end
					default: begin
						state_d <= 'b0;
						x_pos <= x_pos;
						y_pos <= y_pos;
					end
				endcase

				state_d <= state_d + 1'b1;
				if (state_d == 2'b11)
					state_d <= 'b0;

				if (x_pos > X_MAX)
					x_pos <= X_MAX;
				if (y_pos > Y_MAX)
					y_pos <= Y_MAX;
			end 
			else begin
				state_d <= state_d;
				x_pos <= x_pos;
				y_pos <= y_pos;
			end
		end
	end
	
//	PS2_Controller #(1) psm(clock, resetn, command, command_send, PS2_CLK, PS2_DAT, command_conf, command_err, received_data, received_data_en);
	
endmodule

module mouse_mapper(PS2_CLK, PS2_DAT, CLOCK50, KEY, SW, LEDR, HEX3, HEX2, HEX1, HEX0);
	// for physical debugging
	inout PS2_CLK, PS2_DAT;
	input CLOCK50;
	input [3:0] KEY;
	input [9:0] SW;
	output [9:0] LEDR;
	output [6:0] HEX3, HEX2, HEX1, HEX0;
	
	wire mouse_click;
	wire [7:0] x_pos, y_pos;
	wire received_en;
	assign received_en = LEDR[0];
	assign LEDR[1] = mouse_click;
	
	mouse_decoder m0(CLOCK50, PS2_CLK, PS2_DAT, SW[9], mouse_click, x_pos, y_pos, received_en);
	// vga module here
	hex_decoder h0(y_pos[3:0], HEX0);
	hex_decoder h1(y_pos[7:4], HEX1);
	hex_decoder h2(x_pos[3:0], HEX2);
	hex_decoder h3(x_pos[7:4], HEX3);

endmodule

//module mouse_divider(fast_clock, slow_clock, reset, speed);
//	input fast_clock, reset; // 50 MHz
//	input speed; // 1: 100 samples, 0: 200 samples
//	output slow_clock;
//	
//	localparam clock_freq = 50000000;
//	parameter n_upper = $clog2(clock_freq);
//	reg [n_upper + 2:0] downCount;
//	
//	always@(posedge fast_clock) begin
//		if (reset || downCount == 0) begin
//			if (speed) begin // 100 samples
//				downCount <= clock_freq / 100;
//			end else begin // 200 samples
//				downCount <= clock_freq / 200;
//			end
//	end
//endmodule

//module hex_decoder(c, display); // from lab2
//	input [3:0] c;
//	output [6:0] display;
//	
//	assign display[0] = ~((~c[3] & ~c[2] & ~c[1] & ~c[0]) | (~c[3] & ~c[2] & c[1] & ~c[0]) | (~c[3] & ~c[2] & c[1] & c[0]) | (~c[3] & c[2] & ~c[1] & c[0]) | (~c[3] & c[2] & c[1] & ~c[0]) | (~c[3] & c[2] & c[1] & c[0]) | (c[3] & ~c[2] & ~c[1] & ~c[0]) | (c[3] & ~c[2] & ~c[1] & c[0]) | (c[3] & ~c[2] & c[1] & ~c[0]) | (c[3] & c[2] & ~c[1] & ~c[0]) | (c[3] & c[2] & c[1] & ~c[0]) | (c[3] & c[2] & c[1] & c[0]));
//	
//	assign display[1] = ~((~c[3] & ~c[2] & ~c[1] & ~c[0]) | (~c[3] & ~c[2] & ~c[1] & c[0]) | (~c[3] & ~c[2] & c[1] & ~c[0]) | (~c[3] & ~c[2] & c[1] & c[0]) | (~c[3] & c[2] & ~c[1] & ~c[0]) | (~c[3] & c[2] & c[1] & c[0]) | (c[3] & ~c[2] & ~c[1] & ~c[0]) | (c[3] & ~c[2] & ~c[1] & c[0]) | (c[3] & ~c[2] & c[1] & ~c[0]) | (c[3] & c[2] & ~c[1] & c[0]));
//	
//	assign display[2] = ~((~c[3] & ~c[2] & ~c[1] & ~c[0]) | (~c[3] & ~c[2] & ~c[1] & c[0]) | (~c[3] & ~c[2] & c[1] & c[0]) | (~c[3] & c[2] & ~c[1] & ~c[0]) | (~c[3] & c[2] & ~c[1] & c[0]) | (~c[3] & c[2] & c[1] & ~c[0]) | (~c[3] & c[2] & c[1] & c[0]) | (c[3] & ~c[2] & ~c[1] & ~c[0]) | (c[3] & ~c[2] & ~c[1] & c[0]) | (c[3] & ~c[2] & c[1] & ~c[0]) | (c[3] & ~c[2] & c[1] & c[0]) | (c[3] & c[2] & ~c[1] & c[0]));
//	
//	assign display[3] = ~((~c[3] & ~c[2] & ~c[1] & ~c[0]) | (~c[3] & ~c[2] & c[1] & ~c[0]) | (~c[3] & ~c[2] & c[1] & c[0]) | (~c[3] & c[2] & c[1] & ~c[0]) | (~c[3] & c[2] & ~c[1] & c[0]) | (~c[3] & c[2] & c[1] & ~c[0]) | (c[3] & ~c[2] & ~c[1] & ~c[0]) | (c[3] & ~c[2] & ~c[1] & c[0]) | (c[3] & ~c[2] & c[1] & c[0]) | (c[3] & c[2] & ~c[1] & ~c[0]) | (c[3] & c[2] & ~c[1] & c[0]) | (c[3] & c[2] & c[1] & ~c[0]));
//	
//	assign display[4] = ~((~c[3] & ~c[2] & ~c[1] & ~c[0]) | (~c[3] & ~c[2] & c[1] & ~c[0]) | (~c[3] & c[2] & c[1] & ~c[0]) | (c[3] & ~c[2] & ~c[1] & ~c[0]) | (c[3] & ~c[2] & c[1] & ~c[0]) | (c[3] & ~c[2] & c[1] & c[0]) | (c[3] & c[2] & ~c[1] & ~c[0]) | (c[3] & c[2] & ~c[1] & c[0]) | (c[3] & c[2] & c[1] & ~c[0]) | (c[3] & c[2] & c[1] & c[0]));
//	
//	assign display[5] = ~((~c[3] & ~c[2] & ~c[1] & ~c[0]) | (~c[3] & c[2] & ~c[1] & ~c[0]) | (~c[3] & c[2] & ~c[1] & c[0]) | (~c[3] & c[2] & c[1] & ~c[0]) | (c[3] & ~c[2] & ~c[1] & ~c[0]) | (c[3] & ~c[2] & ~c[1] & c[0]) | (c[3] & ~c[2] & c[1] & ~c[0]) | (c[3] & ~c[2] & c[1] & c[0]) | (c[3] & c[2] & ~c[1] & ~c[0]) | (c[3] & c[2] & c[1] & ~c[0]) | (c[3] & c[2] & c[1] & c[0]));
//	
//	assign display[6] = ~((~c[3] & ~c[2] & c[1] & ~c[0]) | (~c[3] & ~c[2] & c[1] & c[0]) | (~c[3] & c[2] & ~c[1] & ~c[0]) | (~c[3] & c[2] & ~c[1] & c[0]) | (~c[3] & c[2] & c[1] & ~c[0]) | (c[3] & ~c[2] & ~c[1] & ~c[0]) | (c[3] & ~c[2] & ~c[1] & c[0]) | (c[3] & ~c[2] & c[1] & ~c[0]) | (c[3] & ~c[2] & c[1] & c[0]) | (c[3] & c[2] & ~c[1] & c[0]) | (c[3] & c[2] & c[1] & ~c[0]) | (c[3] & c[2] & c[1] & c[0]));
//	
//endmodule
