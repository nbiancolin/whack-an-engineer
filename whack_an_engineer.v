module whack_an_engineer(CLOCK_50, KEY, SW, LEDR, HEX5, HEX3, HEX2, HEX1, HEX0, 
                        PS2_CLK, PS2_DAT, 
                        VGA_CLK, VGA_HS, VGA_VS, VGA_BLANK_N, VGA_SYNC_N, VGA_R, VGA_G, VGA_B,
                        AUD_ADCDAT, AUD_BCLK, AUD_ADCLRCK, AUD_DACLRCK, FPGA_I2C_SDAT, FPGA_I2C_SCLK, AUD_XCK, AUD_DACDAT);
    // for DE1-SoC
    input CLOCK_50;
    input [3:0] KEY;
    inout PS2_CLK, PS2_DAT;
    
    // for DE10-Lite
    // input MAX10_CLK1_50; 
    // input [1:0] KEY;
    
    // common ports
    input [9:0] SW;
    output [9:0] LEDR;
    output [6:0] HEX5, HEX3, HEX2, HEX1, HEX0;

    // display
    output VGA_CLK, VGA_HS, VGA_VS, VGA_BLANK_N, VGA_SYNC_N;
    output [7:0] VGA_R, VGA_G, VGA_B;

    // audio
    input AUD_ADCDAT;
    inout AUD_BCLK, AUD_ADCLRCK, AUD_DACLRCK, FPGA_I2C_SDAT;
    output AUD_XCK, AUD_DACDAT, FPGA_I2C_SCLK;
    
    // shared assignments
    wire reset, start;
    assign reset = ~KEY[0];
    assign start = ~KEY[1];

    // wires
    wire [3:0] kb_data_out, data_temp;
    wire kb_key_pressed;
    wire [4:0] molesGenerated;
    wire [2:0] dp_current_state;
    wire [5:0] currentCountDown;
    wire [7:0] score;
    wire moleHit;
    wire [7:0] x_out;
    wire [6:0] y_out;
    wire [2:0] colour_out;
    wire plotEn, doneEn;
//	 wire l_click, m_click, r_click;

    // module instantiation
	 keyboard_decoder kb(PS2_CLK, PS2_DAT, CLOCK_50, reset, kb_data_out, key_pressed, data_temp);
	 mainDataPath dp (.clock(CLOCK_50), .reset(reset), .startGame(start), .userGameInput(kb_data_out[2:0]), .molesGenerated(molesGenerated), .current_state(dp_current_state), .currentCountDown(currentCountDown), .score(score), .moleHit(moleHit));
//    vgaHelper vh(reset, molesGenerated, dp_current_state, moleHit, CLOCK_50, x_out, y_out, colour_out, plotEn, doneEn);
//    vga_adapter VGA(.resetn(reset),
//			        .clock(CLOCK_50),
//                    .colour(colour_out),
//                    .x(x_out),
//                    .y(y_out),
//                    .plot(plotEn),
//                    .VGA_R(VGA_R),
//                    .VGA_G(VGA_G),
//                    .VGA_B(VGA_B),
//                    .VGA_HS(VGA_HS),
//                    .VGA_VS(VGA_VS),
//                    .VGA_BLANK(VGA_BLANK_N),
//                    .VGA_SYNC(VGA_SYNC_N),
//                    .VGA_CLK(VGA_CLK));
//        defparam VGA.RESOLUTION = "160x120";
//		defparam VGA.MONOCHROME = "FALSE";
//		defparam VGA.BITS_PER_COLOUR_CHANNEL = 1;
//		defparam VGA.BACKGROUND_IMAGE = "splash.mif";
//	 audio_decoder ad(CLOCK_50, KEY, start, AUD_ADCDAT, AUD_BCLK, AUD_ADCLRCK, AUD_DACLRCK, FPGA_I2C_SDAT, AUD_XCK, AUD_DACDAT, FPGA_I2C_SCLK, currentCountDown);
//	 mouse md(reset, SW[0], CLOCK_50, PS2_CLK, PS2_DAT, l_click, m_click, r_click, x_out, y_out);

	// physical debugging
	assign LEDR[4:0] = molesGenerated;
	hex_decoder h0(currentCountDown[3:0], HEX0);
   hex_decoder h1({2'b00, currentCountDown[5:4]}, HEX1);
//	hex_decoder h2(molesGenerated[3:0], HEX2);
//	hex_decoder h3({3'b000, molesGenerated[4]}, HEX3);
   hex_decoder h2(score[3:0], HEX2);
   hex_decoder h3(score[7:4], HEX3);
	hex_decoder h5(kb_data_out, HEX5);
	assign LEDR[9] = key_pressed;

endmodule
