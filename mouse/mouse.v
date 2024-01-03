// inspiration from colleagues
// derived from Terasic's official PS2 mouse decoder
//        https://class.ece.uw.edu/271/hauck2/de1/mouse/ps2.v

module mouse (reset, start, clock, PS2_CLK, PS2_DAT, l_click, m_click, r_click, x, y);
  parameter SCREEN_WIDTH = 120;
  parameter SCREEN_HEIGHT = 160;

  // localparam POS_BIT_NUM = $clog2((SCREEN_WIDTH > SCREEN_HEIGHT) ? SCREEN_WIDTH : SCREEN_HEIGHT);

  input reset, start, clock;
  inout PS2_CLK;
  inout PS2_DAT;
  output reg l_click, m_click, r_click;
  output reg [8:0] x;
  output reg [8:0] y;

  localparam enable_cmd = 9'b011110100; // F4, MSB is parity bit

  wire [1:0] curr_state;
  reg [1:0] next_state;
  reg clk_out_en, dat_out_en; // 1: writing, 0: reading
  reg [9:0] data_out;

  reg l_click_latch = 1'b0;
  reg m_click_latch = 1'b0;
  reg r_click_latch = 1'b0;
  reg [8:0] x_latch = 0;
  reg [8:0] y_latch = 0;

  reg [32:0] data_in;
  reg [7:0] idle_count;
  reg [5:0] valid_count;
  reg [3:0] clkpull_delay; 
  reg [3:0] bits_transmitted; 

  reg dat_syn1, clk_syn1, dat_in, clk_in;
  wire dat_syn0, clk_syn0;

  localparam  LISTEN = 2'b00,
              PULLCLK = 2'b01,
              PULLDAT = 2'b10,
              TRANSMIT = 2'b11;

  // done to match mouse clock @ ~97.656 kHz
  wire clk; // slow clock
  mouse_divider mdiv(clock, clk);

  wire clk_out;
  assign clk_out = 1'b0;
  assign PS2_CLK = clk_out_en ? clk_out : 1'bZ; // only clock is pulled down
  wire dat_out;
  assign dat_out = data_out[0];
  assign PS2_DAT = dat_out_en ? dat_out : 1'bZ;
  assign clk_syn0 = clk_out_en ? 1'b1 : PS2_CLK;
  assign dat_syn0 = dat_out_en ? 1'b1 : PS2_DAT;

  reg [9:0] start_timer;
  always @(posedge clock) begin
    if (start)
      start_timer <= 1'b1;
    else if (start_timer)
      start_timer <= start_timer + 1'b1;
    
    l_click = l_click_latch;
    m_click = m_click_latch;
    r_click = r_click_latch;
    x = x_latch;
    y = y_latch;
  end

  // handling clocks in multiple domains?
  always @(posedge clk) begin
    clk_syn1 <= clk_syn0;
    clk_in <= clk_syn1;
    dat_syn1 <= dat_syn0;
    dat_in <= dat_syn1;
  end

  mouse_fsm mfsm(curr_state, next_state, clk, reset);

  // state table
  always @(*) begin
    case (curr_state)
      LISTEN: begin
        if (start_timer && idle_count == 8'b11111111)
          next_state = PULLCLK;
        else begin
          next_state = LISTEN; 
          clk_out_en = 1'b0;
          dat_out_en = 1'b0;
        end
      end
      PULLCLK: begin
        if (clkpull_delay == 4'b1100)
          next_state = PULLDAT;
        else begin
          next_state = PULLCLK;
          clk_out_en = 1'b1; // pull PS2_CLK low
          dat_out_en = 1'b0;
        end
      end
      PULLDAT: begin
        next_state = TRANSMIT;
        clk_out_en = 1'b1;
        dat_out_en = 1'b1;
      end
      TRANSMIT: begin
        if (bits_transmitted == 4'b1010) 
          next_state = LISTEN;
        else begin
          next_state = TRANSMIT;
          clk_out_en = 1'b0;
          dat_out_en = 1'b1;
        end
      end
      default: begin
        next_state = LISTEN;
      end
    endcase
  end

  // counts how long mouse has been in idle mode
  always @(posedge clk) begin
    if ({clk_in, dat_in} == 2'b11)
      idle_count <= idle_count + 1;
    else
      idle_count <= 8'd0;
  end

  // records how much presumably valid data we've received from mouse
  assign flag = (idle_count == 8'hff) ? 1 : 0;
  always @(posedge clk_in, posedge flag) begin
    if (flag)
      valid_count <= 6'b000000; // if we've been idle for too long, mouse probably wasn't sending any valid data, so reset
    else
      valid_count <= valid_count + 1;
  end

  // latching onto data from mouse
  always @(posedge clk) begin
    if (reset) begin // active high
      l_click_latch <= 1'b0;
      m_click_latch <= 1'b0;
      r_click_latch <= 1'b0;

      x_latch <= 0;
      y_latch <= 0;
    end
    else if (curr_state == TRANSMIT) begin
      l_click_latch <= 1'b0;
      m_click_latch <= 1'b0;
      r_click_latch <= 1'b0;
      x_latch <= 0;
      y_latch <= 0;
    end
    else if (idle_count == 8'b00011110 && (valid_count[5] == 1'b1 || valid_count[4] == 1'b1)) begin
      l_click_latch <= data_in[1];
      m_click_latch <= data_in[2];
      r_click_latch <= data_in[3];
      
      if ($signed(x_latch + {data_in[5], data_in[19:12]}) < 0) // test this first; otherwise unsigned interpretation of negative signed could b big unsigned
        x_latch <= 0;
      else if ((x_latch + {data_in[5], data_in[19:12]}) >= SCREEN_WIDTH)
        x_latch <= SCREEN_WIDTH;
      else
        x_latch <= {data_in[5], data_in[19:12]};

      if ($signed(y_latch + {data_in[6], data_in[30:23]}) < 0) 
        y_latch <= 0;
      else if ((y_latch + {data_in[6], data_in[30:23]}) >= SCREEN_HEIGHT)
        y_latch <= SCREEN_HEIGHT;
      else 
        y_latch <= {data_in[6], data_in[30:23]};
    end
  end

  // used to ensure we pull clk low for at least 100us (as a step to start transmission)
  always @(posedge clk) begin
    if (curr_state == PULLCLK)
      clkpull_delay <= clkpull_delay + 1;
    else
      clkpull_delay <= 4'b0000;
  end

  // transmit data to mouse
  always @(negedge clk_in) begin
    if (curr_state == TRANSMIT)
      data_out <= {1'b0, data_out[9:1]};
    else 
      data_out <= {enable_cmd, 1'b0}; 
  end

  // used to count how many bits we've transmitted
  always @(negedge clk_in) begin
    if (curr_state == TRANSMIT)
      bits_transmitted <= bits_transmitted + 1;
    else
      bits_transmitted <= 4'b0000;
  end

  // continually receives data from mouse in listen mode
  always @(negedge clk_in) begin
    if (curr_state == LISTEN)
      data_in <= {dat_in, data_in[32:1]};
  end

endmodule

module mouse_divider(input fast_clock, output slow_clock);
  // for matching polling rate of mouse
  reg [8:0] clk_div;
  always @(posedge fast_clock) begin
    clk_div <= clk_div + 1;
  end
  assign slow_clock = clk_div[8];
endmodule

module mouse_fsm(curr_state, next_state, clk, reset);
  output reg [1:0] curr_state;
  input [1:0] next_state;
  input clk, reset;

  // state change
  always @(posedge clk) begin
    if (reset) // active high
      curr_state <= 2'b01; // not sure if this should be pullclk
    else 
      curr_state <= next_state;
  end

endmodule