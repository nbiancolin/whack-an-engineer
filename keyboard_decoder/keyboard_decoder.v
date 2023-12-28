`timescale 1ns / 1ns // `timescale time_unit/time_precision

module keyboard_decoder #(parameter X_SIZE = 160, Y_SIZE = 120) (PS2_CLK, PS2_DAT, clock, reset, data_out, key_pressed, data_temp);
	inout PS2_CLK, PS2_DAT;
	input clock, reset;
	output reg [3:0] data_out;
	output reg key_pressed;
	
	output [7:0] data_temp;
	wire pressed_temp;
	reg [7:0] previous_key;
//	wire slow_clock;
	
	PS2_Controller(.CLOCK_50(clock), .reset(reset), .PS2_CLK(PS2_CLK), .PS2_DAT(PS2_DAT), .received_data(data_temp), .received_data_en(pressed_temp));
//	peripheral_divider(clock, slow_clock);
	
	localparam		Z_MAKE		=	8'h1A,
					X_MAKE		=	8'h22,
					C_MAKE		=	8'h21,
					V_MAKE		=	8'h2A,
					B_MAKE		=	8'h32,
					BREAK		=	8'hF0;
	
	always@(posedge clock) begin
		// check for key on/off
		if (reset) begin
        data_out <= 4'b0;
        previous_key <= 4'b0;
        key_pressed <= 1'b0;
		end else begin
        if (data_temp == BREAK) begin
            data_out <= 4'b0;
            key_pressed <= 1'b0;
        end else if (pressed_temp && (data_temp != previous_key)) begin
            previous_key <= data_temp;
            key_pressed <= 1'b1;
        end
        if (key_pressed) begin
            case (data_temp)
                Z_MAKE: data_out <= 4'd5;
                X_MAKE: data_out <= 4'd4;
                C_MAKE: data_out <= 4'd3;
                V_MAKE: data_out <= 4'd2;
                B_MAKE: data_out <= 4'd1;
                BREAK: data_out <= 4'd0;
                default: data_out <= 4'd0;
            endcase
        end
		end
	end
endmodule

module keyboard_mapper(CLOCK50, KEY, SW, PS2_CLK, PS2_DAT, HEX5, HEX4, HEX0, LEDR);
	// for physical debugging/testing
	input CLOCK50;
	input [3:0] KEY;
	input [9:0] SW;
	inout PS2_CLK, PS2_DAT;
	output [6:0] HEX5, HEX4, HEX0;
	output [1:0] LEDR;
	
	wire [3:0] data_out;
	wire key_pressed;
	assign LEDR[0] = key_pressed;
	assign LEDR[1] = ~KEY[0];
	wire [7:0] data_temp;
	
	keyboard_decoder kb(PS2_CLK, PS2_DAT, CLOCK50, ~KEY[0], data_out, key_pressed, data_temp);
	hex_decoder h0(data_out[3:0], HEX0);
	hex_decoder h4(data_temp[3:0], HEX4);
	hex_decoder h5(data_temp[7:4], HEX5);

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
