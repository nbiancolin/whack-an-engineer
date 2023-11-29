`timescale 1ns / 1ns // `timescale time_unit/time_precision

module keyboard_decoder #(parameter X_SIZE = 160, Y_SIZE = 120) (PS2_CLK, PS2_DAT, clock, reset, data_out, key_pressed);
	inout PS2_CLK, PS2_DAT;
	input clock, reset;
	output reg [3:0] data_out;
	output reg key_pressed;
	
	wire [7:0] data_temp;
	wire pressed_temp;
	reg [7:0] previous_key;
//	wire slow_clock;
	
	PS2_Controller(.CLOCK_50(clock), .reset(reset), .PS2_CLK(PS2_CLK), .PS2_DAT(PS2_DAT), .received_data(data_temp), .received_data_en(pressed_temp));
//	peripheral_divider(clock, slow_clock);
	
	localparam		Z_MAKE		=	8'h1A,
						X_MAKE		=	8'h1A,
						C_MAKE		=	8'h21,
						V_MAKE		=	8'h2A,
						B_MAKE		=	8'h32,
						BREAK			=	8'hF0;
	
	always@(posedge clock) begin
		// check for key on/off
		if (reset) begin
			data_out <= 'b0;
			previous_key <= 'b0;
			key_pressed <= 'b0;
		end
		else begin
			if (data_temp == BREAK) begin
				data_out <= 'b0;
				key_pressed <= 'b0;
			end else begin			
				if (pressed_temp) begin // check if enable goes on for break
	//				else if (data_temp == previous_key) begin
	//					data_out <= 'b0;
	//					key_pressed <= 'b0;
	//				end
					if (data_temp != previous_key && data_temp != BREAK) begin // for unique key
						previous_key <= data_temp;
						key_pressed <= 'b1;
					end
					
					case(data_temp)
							Z_MAKE: data_out <= 4'd1;
							X_MAKE: data_out <= 4'd2;
							C_MAKE: data_out <= 4'd3;
							V_MAKE: data_out <= 4'd4;
							B_MAKE: data_out <= 4'd5;
							BREAK: data_out <= 4'd0;
							default: data_out <= 4'd0;
					endcase
				end
				else begin
					data_out <= data_out;
					previous_key <= previous_key;
					key_pressed <= key_pressed;
				end
			end
		end
	end
	
endmodule

module keyboard_mapper(CLOCK50, KEY, SW, PS2_CLK, PS2_DAT, HEX0, LEDR);
	// for physical debugging/testing
	input CLOCK50;
	input [3:0] KEY;
	input [9:0] SW;
	inout PS2_CLK, PS2_DAT;
	output [6:0] HEX0;
	output [9:0] LEDR;
	
	wire [3:0] data_out;
	wire key_pressed;
	assign LEDR[0] = key_pressed;
	assign LEDR[1] = ~KEY[0];
	
	keyboard_decoder kb(PS2_CLK, PS2_DAT, CLOCK50, ~KEY[0], data_out, key_pressed);
	hex_decoder h0(data_out[3:0], HEX0);

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

module peripheral_divider(clock, enable_sig);
	input clock; // clock50
	output reg enable_sig;
	
	parameter upperLim = 10000;
	parameter upperBits = 14;
	reg [15:0] count;
	
	always@(posedge clock) begin
		if (count < 10000 && count >= 0) begin
			count <= count + 1;
			enable_sig <= 'b0;
		end
		else if (count == 10000) begin
			enable_sig <= 'b1;
			count <= 'b0;
		end
		else begin
			enable_sig <= 'b0;
			count <='b0;
		end
	end

endmodule
