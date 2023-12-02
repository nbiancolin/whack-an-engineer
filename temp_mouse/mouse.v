// ideas and inspiration from peers and colleagues
// derived from Terasic's official code
//			https://class.ece.uw.edu/271/hauck2/de1/mouse/ps2.v	

module mouse_decoder(reset, enable, clock, PS2_CLK, PS2_DAT, x, y, l_click, r_click, m_click);

	input reset, enable, clock;
	inout PS2_CLK, PS2_DAT;
	output reg [7:0] x, y;
	output reg l_click, r_click, m_click;

	parameter X_MAX = 'd160, Y_MAX = 'd120;
	parameter 	S_LISTEN	= 2'b00;
				S_PULLCLK	= 2'b01;
				S_PULLDAT	= 2'b10;
				S_CHANGE	= 2'b11;

	wire slow_clock; // matches mouse polling rate
	mouse_divider md(reset, clock, slow_clock);

	reg PS2_CLK_en, PS2_DAT_en; // 1: writing, 0: reading
	
	// start-up stage
	reg [3:0] start_delay;
	always@(posedge slow_clock) begin
		// needs clk low for 100 us start-up before transmission begins
		if (curr_state == S_PULLCLK)
			start_delay <= start_delay + 1;
		else
			start_delay <= 'b0;
	end

	reg [7:0] idle_count;
	always@(posedge slow_clock) begin
		// checks how long mouse has been idling
		if ({PS2_CLK_en, PS2_DAT_en} == 2'b11)
			idle_count <= idle_count + 1;
		else
			idle_count <= 8'd0;
	end

	reg [2:0] curr_state, next_state;
	mouse_fsm mf(slow_clock, reset, curr_state, next_state);
	
endmodule

module mouse_fsm(clock, reset, curr_state, next_state);
	input clock, reset;
	input [2:0] next_state;
	output reg [2:0] curr_state;

	parameter 	S_LISTEN	= 2'b00;
				S_PULLCLK	= 2'b01;
				S_PULLDAT	= 2'b10;
				S_CHANGE	= 2'b11;

	// state table
	always@(*) begin
		case(curr_state)
			S_LISTEN:
			S_PULLCLK:
			S_PULLDAT:
			S_CHANGE:
			default: next_state = S_LISTEN;
	end
	
	// state change at clock
	always@(posedge clock or negedge reset) begin
		if (reset) // active high reset
			curr_state <= S_PULLCLK; // reset state
		else
			curr_state <= next_state;
	end

endmodule

module mouse_divider(reset, clock, slow_clock);
	// matches 50 MHz clock on the board with internal mouse poll rate
	input reset, clock;
	output slow_clock;

	reg [8:0] counter;

	always@(posedge clock or negedge reset) begin
		// this method from the official code
		if (reset)
			counter <= 'b0;
		else
			counter <= counter + 1;
	end

	assign slow_clock = counter[8];

endmodule
