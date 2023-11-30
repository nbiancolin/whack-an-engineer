`timescale 1ns / 1ns // `timescale time_unit/time_precision

module pseudo_rng(clock, reset, generateEn, output_data);
	// pseudo rng relying on fast clocks
	input clock, reset, generateEn;
	output reg [4:0] output_data;
	
	reg [2:0] temp_data;
	parameter uppermax = $clog2(10000000);
	reg [uppermax + 2:0] counter;
	
	always@(posedge clock) begin
		if (reset) begin
			counter <= 'b0;
			temp_data <= 'b0;
		end 
		else begin
			if (counter < 10000000 && counter >= 0)
				counter <= counter + 1;
			else
				counter <= 'b0;
		end
	end
	
	always@(posedge generateEn) begin
		temp_data = counter % 5; // 0-4
		
		case(temp_data) // one hot encoding
			3'b000: output_data <= 5'b00001;
			3'b001: output_data <= 5'b00010;
			3'b010: output_data <= 5'b00100;
			3'b011: output_data <= 5'b01000;
			3'b100: output_data <= 5'b10000;
		endcase
	end
endmodule
