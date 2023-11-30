
// used zach's code and this code as reference: https://class.ece.uw.edu/271/hauck2/de1/mouse/ps2.v

module mouse (resetn, start, CLOCK_50, PS2_CLK, PS2_DAT, leftclick, x, y, cState);

  parameter SCREEN_WIDTH = 320; // check this later
  parameter SCREEN_HEIGHT = 240;

  // localparam POS_BIT_NUM = $clog2((SCREEN_WIDTH > SCREEN_HEIGHT) ? SCREEN_WIDTH : SCREEN_HEIGHT);

  input resetn;
  input CLOCK_50;
  inout PS2_CLK;
  inout PS2_DAT;
  input start;

  output reg leftclick;
  output reg [8:0] x;
  output reg [8:0] y;

  localparam enable_cmd = 9'b011110100; // F4, MSB is parity bit

  output reg [1:0] cState;
  reg [1:0] nState;
  reg clk_out_en, dat_out_en; // when these r 1, we're outputting clk and dat, when 0, we're reading them in
  reg [9:0] data_out;

  reg leftclick_latch = 1'b0;
  reg [8:0] x_latch = 0;
  reg [8:0] y_latch = 0;

  reg [32:0] data_in;
  reg [7:0] idle_count;
  reg [5:0] valid_count;
  reg [3:0] clkpull_delay; 
  reg [3:0] bits_transmitted; 

  reg dat_syn1, clk_syn1, dat_in, clk_in;
  wire dat_syn0, clk_syn0;

  localparam LISTEN = 2'b00, PULLCLK = 2'b01, PULLDAT = 2'b10, TRANSMIT = 2'b11;

  // clk is 97.65625KHz derived from 50MHz CLOCK_50

  reg [8:0] clk_div;
  wire clk;
  always @(posedge CLOCK_50) begin
    clk_div <= clk_div + 1;
  end
  assign clk = clk_div[8];

  wire clk_out;
  assign clk_out = 1'b0;
  assign PS2_CLK = clk_out_en ? clk_out : 1'bZ; // we'll only have to pull the clk down
  wire dat_out;
  assign dat_out = data_out[0];
  assign PS2_DAT = dat_out_en ? dat_out : 1'bZ;
  assign clk_syn0 = clk_out_en ? 1'b1 : PS2_CLK;
  assign dat_syn0 = dat_out_en ? 1'b1 : PS2_DAT;

  reg [9:0] starttimer;
  always @(posedge CLOCK_50) begin
    if (start) starttimer <= 1'b1;
    else if (starttimer) starttimer <= starttimer + 1'b1;
    leftclick = leftclick_latch;
    x = x_latch;
    y = y_latch;
  end

  // handling clocks in multiple domains i believe?
  always @(posedge clk) begin
    clk_syn1 <= clk_syn0;
    clk_in <= clk_syn1;
    dat_syn1 <= dat_syn0;
    dat_in <= dat_syn1;
  end

  // communication FSM
  always @(*) begin
    case (cState)
      LISTEN: begin
        if (starttimer && idle_count == 8'b11111111)
          nState = PULLCLK;
        else begin
          nState = LISTEN; 
          clk_out_en = 1'b0;
          dat_out_en = 1'b0;
        end
      end
      PULLCLK: begin
        if (clkpull_delay == 4'b1100)
          nState = PULLDAT;
        else begin
          nState = PULLCLK;
          clk_out_en = 1'b1; // pull PS2_CLK low
          dat_out_en = 1'b0;
        end
      end
      PULLDAT: begin
        nState = TRANSMIT;
        clk_out_en = 1'b1;
        dat_out_en = 1'b1;
      end
      TRANSMIT: begin
        if (bits_transmitted == 4'b1010) 
          nState = LISTEN;
        else begin
          nState = TRANSMIT;
          clk_out_en = 1'b0;
          dat_out_en = 1'b1;
        end
      end
      default: begin
        nState = LISTEN;
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
  always @(posedge clk, negedge resetn) begin
    if (!resetn) begin
      leftclick_latch <= 1'b0;
      x_latch <= 0;
      y_latch <= 0;
    end
    else if (cState == TRANSMIT) begin
      leftclick_latch <= 1'b0;
      x_latch <= 0;
      y_latch <= 0;
    end
    else if (idle_count == 8'b00011110 && (valid_count[5] == 1'b1 || valid_count[4] == 1'b1)) begin
      leftclick_latch <= data_in[1];
      
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
    if (cState == PULLCLK)
      clkpull_delay <= clkpull_delay + 1;
    else
      clkpull_delay <= 4'b0000;
  end

  // transmit data to mouse
  always @(negedge clk_in) begin
    if (cState == TRANSMIT)
      data_out <= {1'b0, data_out[9:1]};
    else 
      data_out <= {enable_cmd, 1'b0}; 
  end

  // used to count how many bits we've transmitted
  always @(negedge clk_in) begin
    if (cState == TRANSMIT)
      bits_transmitted <= bits_transmitted + 1;
    else
      bits_transmitted <= 4'b0000;
  end

  // continually receives data from mouse in listen mode
  always @(negedge clk_in) begin
    if (cState == LISTEN)
      data_in <= {dat_in, data_in[32:1]};
  end

  always @(posedge clk, negedge resetn) begin
    if (!resetn)
      cState <= PULLCLK; // should it b PULLCLK?
    else 
      cState <= nState;
  end
endmodule