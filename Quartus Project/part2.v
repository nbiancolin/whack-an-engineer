module vgaHelper(iResetn, hhSelect, hhState, clk, oX, oY, oColour, oPlot, oDone);
    parameter X_SCREEN_PIXELS = 8'd160;
    parameter Y_SCREEN_PIXELS = 7'd120;
    parameter CLOCK_FREQ = 13'd100; //LATER match this with board freq
    input iResetn, clk;  //(iresetn is [0])
    input [2:0] hhState; //one hot encoding since switches   (this should be KEY[3:1] since KEY[0] is reset)
    input [4:0] hhSelect; //Also one-hot encoding (switches SW[4:0])

    output reg [7:0] oX; //coords that are being written
    output reg [6:0] oY;
    output reg [2:0] oColour;
    output reg oPlot, oDone;

	localparam	X_HH = 8'd30,
				Y_HH = 7'd20,
				//Hard Hat top starting coords (going ccw)
				//ONE: 
				X_1 = 47,
				Y_1 = 15,
				//TWO:
				X_2 = 97,
				Y_2 = 31,
				//THREE:
				X_3 = 126,
				Y_3 = 63,
				//FOUR:
				X_4 = 67,
				Y_4 = 82,
				//FIVE: 
				X_5 = 10,
				Y_5 = 53;


    localparam  P_RST       = 3'd0,     //draws over initial screen (from mif or with plot algo)
                RST         = 3'd1,     //waiting for input to start game
                W_LOADING   = 3'd2,     //waiting for release of input button
                P_HH        = 3'd3,     //plots hh's on screen for waiting for start (one each second, returning to W_LOADING after the first two, then going to)
                P_GAME      = 3'd4,     //plots full screen (whether it be from mif or full colour)
                GAME        = 3'd5,     //waits for input
                W_GAME      = 3'd6,		//state / etc are stored here;
                P_HH_GAME   = 3'd7;		//draws hh at right spot

    localparam  HH_1 = 5'b00001, //assuming only one switch is on at any given point
                HH_2 = 5'b00010, //for switches
                HH_3 = 5'b00100,
                HH_4 = 5'b01000,
                HH_5 = 5'b10000;

    localparam  HH_REST     = 3'b001, //for states
                HH_READY    = 3'b010,
                HH_HIT      = 3'b100;

    
    reg [2:0] curState, nextState;
    reg [7:0] Xsize;            //upper bound of counter
    reg [6:0] Ysize;
    reg [7:0] xProgress;        //counter
    reg [6:0] yProgress;

    wire [2:0] hhCol, splashCol, gSteadyCol;

    reg [15:0] counter;
	reg [14:0] address;
	
	reg [1:0] selector;
	/*
	select states:
	00 - outline (rest)
	01 - coloured in ('ready')
	10 - hit
	11 - bonus? (// counter)
	*/

    reg [3:0] stoHHState;
	reg [4:0] stoHHSelect;

    reg [1:0] loading; //counter for # of HH's drawn
/*
How this code aims to work (to simulate eric's code)

use 5 switches to simulate which hard hat is selected by Eric's code
use buttons to toggle what state each one should be in (state of each is stored in register)


use button 3 (left most) to initialize start of game (HH_HIT)

reset should re-draw start screen

*/
	colourSelect c0(.clk(clk), .resetn(iResetn), .xProgress(xProgress), .yProgress(yProgress), .selector(stoHHState), .color(hhCol)); //handles what colour should be outputted

	
	splash s0(.address(address), .clock(clk), .data(3'b000), .wren(1'b0), .q(splashCol));
	g_steady g0(.address(address), .clock(clk), .data(3'b000), .wren(1'b0), .q(gSteadyCol));
	
    always@(*) begin
        case(curState)
        P_RST: 
            nextState <= oDone ? RST : P_RST;
        RST:
            nextState <= (hhState == HH_HIT) ? W_LOADING : RST;
        W_LOADING:
            nextState <= (hhState == 3'b000 && counter == 0) ? P_GAME : W_LOADING;
        P_HH: begin
			if(|loading) //bitwise or, so if any of the bits are 1, this evaluates to true
				if(oDone) nextState <= W_LOADING;
				else nextState <= P_HH;
			else nextState <= P_GAME; 
		end
		P_GAME:
			nextState <= oDone ? GAME : P_GAME;
		GAME:
			nextState <= (|hhState) ? W_GAME : GAME;
		W_GAME: //might remove this later when integrating with Eric's code;
			nextState <= (|hhState) ?  W_GAME: P_HH_GAME;
		P_HH_GAME:
			nextState <= oDone ? GAME : P_HH_GAME;
		endcase
    end

	always@(posedge clk) begin
		if(iResetn) begin  //active high TODO: fix in fill.v
            curState <= P_RST;
            oX <= 0;
            oY <= 0;
			oDone <= 0;
			address <= 0;
            xProgress <= 0;
            yProgress <= 0;
			//Xsize <= X_SCREEN_PIXELS -1;
			//Ysize <= Y_SCREEN_PIXELS -1;
			counter <= CLOCK_FREQ;
			loading <= 2'b11;
        end
		else begin
			curState <= nextState;
			
			case(curState)
			P_RST: begin  //memory code judraws box, only different is colour comes from memory
				oColour <= splashCol;
                address <= address +1;
				if (!oDone) begin
                oPlot <= 1;  
                if (xProgress < X_SCREEN_PIXELS -1) begin
                    oX <= oX + 1; 
                    xProgress <= xProgress + 1;  
                end else begin
                //if (xProgress == Xsize) begin
                    oX <= oX - xProgress;  
                    xProgress <= 0; 
                    if (yProgress < Y_SCREEN_PIXELS -1) begin
                        oY <= oY + 1;  
                        yProgress <= yProgress + 1; 
                    end
                end
                if (xProgress == (X_SCREEN_PIXELS -1) && yProgress == (Y_SCREEN_PIXELS -1)) begin
                    oDone <= 1;  
                    oPlot <= 0;  
					//loading = loading + 1;
                    oX <= 0;
                    oY <= 0;
                    oX <= 0;
                    oY <= 0;
                    address <= 0;
                end
            end else begin
                oDone <= 1; 
            end
			end
			RST: address <= 0;//oDone <= 1'b1;//does anything happen here?
			W_LOADING: begin
				//Xsize <= X_HH -1;
				//Ysize <= Y_HH -1;
				//probably other shit
				counter <= counter -1;
				selector <= 2'b11; // (this should select a colourful one
                oDone <= 0;
                address <= 0;
                xProgress <= 0;
                yProgress <= 0;
			end
			P_HH: begin
				counter <= CLOCK_FREQ;
				oColour <= hhCol;
				if (!oDone) begin
                oPlot <= 1;  
                if (xProgress < X_HH -1) begin
                    oX <= oX + 1; 
                    xProgress <= xProgress + 1;  
                end else begin
                //if (xProgress == Xsize) begin
                    oX <= oX - xProgress;  
                    xProgress <= 0; 
                    if (yProgress < Y_HH -1) begin
                        oY <= oY + 1;  
                        yProgress <= yProgress + 1; 
                    end
                end
                if (xProgress == (X_HH -1) && yProgress == (Y_HH -1)) begin
                    oDone <= 1;  
                    oPlot <= 0;  
                    oX <= 0;
                    oY <= 0;
					loading = loading -1;
                end
            end else begin
                oDone <= 1;
                loading = loading -1; 
            end
			end
			P_GAME: begin
			//plot code that uses memory
                oColour <= gSteadyCol;
                address <= address +1;
				if (!oDone) begin
                oPlot <= 1;  
                if (xProgress < X_SCREEN_PIXELS -1) begin
                    oX <= oX + 1; 
                    xProgress <= xProgress + 1;  
                end else begin
                //if (xProgress == Xsize) begin
                    oX <= oX - xProgress;  
                    xProgress <= 0; 
                    if (yProgress < Y_SCREEN_PIXELS -1) begin
                        oY <= oY + 1;  
                        yProgress <= yProgress + 1; 
                    end
                end
                if (xProgress == (X_SCREEN_PIXELS -1) && yProgress == (Y_SCREEN_PIXELS -1)) begin
                    oDone <= 1;  
                    oPlot <= 0;  
					//loading = loading + 1;
                    oX <= 0;
                    oY <= 0;
                    address <= 0;
                end
            end else begin
                oDone <= 1; 
            end
			end
			GAME: begin
				oDone <= 0;//does anything acc happen in this state
				yProgress <= 0;
			end
			W_GAME: begin
				stoHHState <= hhState;
				case(hhSelect) //decoding hhSelect
				HH_1: begin
					oX <= X_1;
					oY <= Y_1;
				end
				HH_2: begin
					oX <= X_2;
					oY <= Y_2;
				end
				HH_3: begin
					oX <= X_3;
					oY <= Y_3;
				end
				HH_4: begin
					oX <= X_4;
					oY <= Y_4;
				end
				HH_5: begin
					oX <= X_5;
					oY <= Y_5;
				end
				endcase
			end
			P_HH_GAME: begin
				//decode stoHHselect and hhstate
				//acc plot
                oColour <= hhCol; //colour not being set currectly
				//oColour <= splashCol;
                //address <= address +1;
				if (!oDone) begin
                oPlot <= 1;  
                if (xProgress < X_HH -1) begin
                    oX <= oX + 1; 
                    xProgress <= xProgress + 1;  
                end else begin
                //if (xProgress == Xsize) begin
                    oX <= oX - xProgress;  
                    xProgress <= 0; 
                    if (yProgress < Y_HH -1) begin
                        oY <= oY + 1;  
                        yProgress <= yProgress + 1; 
                    end
                end
                if (xProgress == (X_HH -1) && yProgress == (Y_HH -1)) begin
                    oDone <= 1;  
                    oPlot <= 0;  
					//loading = loading + 1;
                    oX <= 0;
                    oY <= 0;
                    oX <= 0;
                    oY <= 0;
                    address <= 0;
                end
				end
				end
			endcase
		end
	end


endmodule


module colourSelect(clk, resetn, xProgress, yProgress, selector, color);  //fixed
    input clk;
    input resetn;
    input [7:0] xProgress;
    input [6:0] yProgress;
    input [3:0] selector;

    output reg [2:0] color;

    always@(posedge clk) begin
        if(!resetn) color <= 3'b000; 
        else if (selector == 3'b001) begin//HH Outline
            if(xProgress == 0 && yProgress == 0) color <= 3'b000;
            else if(xProgress == 11 && yProgress == 2) color <= 3'b111;
            else if(xProgress == 16 && yProgress == 2) color <= 3'b000;
            else if(xProgress == 10 && yProgress == 3) color <= 3'b111;
            else if(xProgress == 12 && yProgress == 3) color <= 3'b000;
            else if(xProgress == 15 && yProgress == 3) color <= 3'b111;
            else if(xProgress == 20 && yProgress == 3) color <= 3'b000;
            else if(xProgress == 8 && yProgress == 4) color <= 3'b111;
            else if(xProgress == 10 && yProgress == 4) color <= 3'b000;
            else if(xProgress == 11 && yProgress == 4) color <= 3'b111;
            else if(xProgress == 12 && yProgress == 4) color <= 3'b000;
            else if(xProgress == 16 && yProgress == 4) color <= 3'b111;
            else if(xProgress == 17 && yProgress == 4) color <= 3'b000;
            else if(xProgress == 19 && yProgress == 4) color <= 3'b111;
            else if(xProgress == 21 && yProgress == 4) color <= 3'b000;
            else if(xProgress == 7 && yProgress == 5) color <= 3'b111;
            else if(xProgress == 9 && yProgress == 5) color <= 3'b000;
            else if(xProgress == 10 && yProgress == 5) color <= 3'b111;
            else if(xProgress == 11 && yProgress == 5) color <= 3'b000;
            else if(xProgress == 12 && yProgress == 5) color <= 3'b111;
            else if(xProgress == 14 && yProgress == 5) color <= 3'b000;
            else if(xProgress == 17 && yProgress == 5) color <= 3'b111;
            else if(xProgress == 19 && yProgress == 5) color <= 3'b000;
            else if(xProgress == 20 && yProgress == 5) color <= 3'b111;
            else if(xProgress == 21 && yProgress == 5) color <= 3'b000;
            else if(xProgress == 6 && yProgress == 6) color <= 3'b111;
            else if(xProgress == 10 && yProgress == 6) color <= 3'b000;
            else if(xProgress == 11 && yProgress == 6) color <= 3'b111;
            else if(xProgress == 12 && yProgress == 6) color <= 3'b000;
            else if(xProgress == 13 && yProgress == 6) color <= 3'b111;
            else if(xProgress == 15 && yProgress == 6) color <= 3'b000;
            else if(xProgress == 18 && yProgress == 6) color <= 3'b111;
            else if(xProgress == 22 && yProgress == 6) color <= 3'b000;
            else if(xProgress == 6 && yProgress == 7) color <= 3'b111;
            else if(xProgress == 7 && yProgress == 7) color <= 3'b000;
            else if(xProgress == 10 && yProgress == 7) color <= 3'b111;
            else if(xProgress == 11 && yProgress == 7) color <= 3'b000;
            else if(xProgress == 15 && yProgress == 7) color <= 3'b111;
            else if(xProgress == 16 && yProgress == 7) color <= 3'b000;
            else if(xProgress == 19 && yProgress == 7) color <= 3'b111;
            else if(xProgress == 20 && yProgress == 7) color <= 3'b000;
            else if(xProgress == 22 && yProgress == 7) color <= 3'b111;
            else if(xProgress == 23 && yProgress == 7) color <= 3'b000;
            else if(xProgress == 5 && yProgress == 8) color <= 3'b111;
            else if(xProgress == 7 && yProgress == 8) color <= 3'b000;
            else if(xProgress == 8 && yProgress == 8) color <= 3'b111;
            else if(xProgress == 10 && yProgress == 8) color <= 3'b000;
            else if(xProgress == 15 && yProgress == 8) color <= 3'b111;
            else if(xProgress == 17 && yProgress == 8) color <= 3'b000;
            else if(xProgress == 19 && yProgress == 8) color <= 3'b111;
            else if(xProgress == 21 && yProgress == 8) color <= 3'b000;
            else if(xProgress == 22 && yProgress == 8) color <= 3'b111;
            else if(xProgress == 23 && yProgress == 8) color <= 3'b000;
            else if(xProgress == 5 && yProgress == 9) color <= 3'b111;
            else if(xProgress == 6 && yProgress == 9) color <= 3'b000;
            else if(xProgress == 8 && yProgress == 9) color <= 3'b111;
            else if(xProgress == 9 && yProgress == 9) color <= 3'b000;
            else if(xProgress == 16 && yProgress == 9) color <= 3'b111;
            else if(xProgress == 17 && yProgress == 9) color <= 3'b000;
            else if(xProgress == 20 && yProgress == 9) color <= 3'b111;
            else if(xProgress == 21 && yProgress == 9) color <= 3'b000;
            else if(xProgress == 23 && yProgress == 9) color <= 3'b111;
            else if(xProgress == 24 && yProgress == 9) color <= 3'b000;
            else if(xProgress == 5 && yProgress == 10) color <= 3'b111;
            else if(xProgress == 6 && yProgress == 10) color <= 3'b000;
            else if(xProgress == 11 && yProgress == 10) color <= 3'b111;
            else if(xProgress == 14 && yProgress == 10) color <= 3'b000;
            else if(xProgress == 16 && yProgress == 10) color <= 3'b111;
            else if(xProgress == 17 && yProgress == 10) color <= 3'b000;
            else if(xProgress == 20 && yProgress == 10) color <= 3'b111;
            else if(xProgress == 22 && yProgress == 10) color <= 3'b000;
            else if(xProgress == 23 && yProgress == 10) color <= 3'b111;
            else if(xProgress == 24 && yProgress == 10) color <= 3'b000;
            else if(xProgress == 4 && yProgress == 11) color <= 3'b111;
            else if(xProgress == 6 && yProgress == 11) color <= 3'b000;
            else if(xProgress == 10 && yProgress == 11) color <= 3'b111;
            else if(xProgress == 12 && yProgress == 11) color <= 3'b000;
            else if(xProgress == 13 && yProgress == 11) color <= 3'b111;
            else if(xProgress == 14 && yProgress == 11) color <= 3'b000;
            else if(xProgress == 16 && yProgress == 11) color <= 3'b111;
            else if(xProgress == 18 && yProgress == 11) color <= 3'b000;
            else if(xProgress == 21 && yProgress == 11) color <= 3'b111;
            else if(xProgress == 22 && yProgress == 11) color <= 3'b000;
            else if(xProgress == 23 && yProgress == 11) color <= 3'b111;
            else if(xProgress == 26 && yProgress == 11) color <= 3'b000;
            else if(xProgress == 3 && yProgress == 12) color <= 3'b111;
            else if(xProgress == 4 && yProgress == 12) color <= 3'b000;
            else if(xProgress == 5 && yProgress == 12) color <= 3'b111;
            else if(xProgress == 6 && yProgress == 12) color <= 3'b000;
            else if(xProgress == 7 && yProgress == 12) color <= 3'b111;
            else if(xProgress == 9 && yProgress == 12) color <= 3'b000;
            else if(xProgress == 10 && yProgress == 12) color <= 3'b111;
            else if(xProgress == 11 && yProgress == 12) color <= 3'b000;
            else if(xProgress == 13 && yProgress == 12) color <= 3'b111;
            else if(xProgress == 14 && yProgress == 12) color <= 3'b000;
            else if(xProgress == 17 && yProgress == 12) color <= 3'b111;
            else if(xProgress == 18 && yProgress == 12) color <= 3'b000;
            else if(xProgress == 21 && yProgress == 12) color <= 3'b111;
            else if(xProgress == 22 && yProgress == 12) color <= 3'b000;
            else if(xProgress == 23 && yProgress == 12) color <= 3'b111;
            else if(xProgress == 24 && yProgress == 12) color <= 3'b000;
            else if(xProgress == 25 && yProgress == 12) color <= 3'b111;
            else if(xProgress == 27 && yProgress == 12) color <= 3'b000;
            else if(xProgress == 3 && yProgress == 13) color <= 3'b111;
            else if(xProgress == 4 && yProgress == 13) color <= 3'b000;
            else if(xProgress == 5 && yProgress == 13) color <= 3'b111;
            else if(xProgress == 7 && yProgress == 13) color <= 3'b000;
            else if(xProgress == 9 && yProgress == 13) color <= 3'b111;
            else if(xProgress == 14 && yProgress == 13) color <= 3'b000;
            else if(xProgress == 17 && yProgress == 13) color <= 3'b111;
            else if(xProgress == 18 && yProgress == 13) color <= 3'b000;
            else if(xProgress == 21 && yProgress == 13) color <= 3'b111;
            else if(xProgress == 23 && yProgress == 13) color <= 3'b000;
            else if(xProgress == 26 && yProgress == 13) color <= 3'b111;
            else if(xProgress == 27 && yProgress == 13) color <= 3'b000;
            else if(xProgress == 4 && yProgress == 14) color <= 3'b111;
            else if(xProgress == 5 && yProgress == 14) color <= 3'b000;
            else if(xProgress == 7 && yProgress == 14) color <= 3'b111;
            else if(xProgress == 9 && yProgress == 14) color <= 3'b000;
            else if(xProgress == 11 && yProgress == 14) color <= 3'b111;
            else if(xProgress == 13 && yProgress == 14) color <= 3'b000;
            else if(xProgress == 14 && yProgress == 14) color <= 3'b111;
            else if(xProgress == 22 && yProgress == 14) color <= 3'b000;
            else if(xProgress == 26 && yProgress == 14) color <= 3'b111;
            else if(xProgress == 27 && yProgress == 14) color <= 3'b000;
            else if(xProgress == 5 && yProgress == 15) color <= 3'b111;
            else if(xProgress == 9 && yProgress == 15) color <= 3'b000;
            else if(xProgress == 25 && yProgress == 15) color <= 3'b111;
            else if(xProgress == 27 && yProgress == 15) color <= 3'b000;
            else if(xProgress == 8 && yProgress == 16) color <= 3'b111;
            else if(xProgress == 11 && yProgress == 16) color <= 3'b000;
            else if(xProgress == 24 && yProgress == 16) color <= 3'b111;
            else if(xProgress == 26 && yProgress == 16) color <= 3'b000;
            else if(xProgress == 10 && yProgress == 17) color <= 3'b111;
            else if(xProgress == 25 && yProgress == 17) color <= 3'b000;
        end 
        else if(selector == 2'b01) begin //HH Ready
            if(xProgress == 0 && yProgress == 0) color <= 3'b000;
            else if(xProgress == 11 && yProgress == 2) color <= 3'b100;
            else if(xProgress == 16 && yProgress == 2) color <= 3'b000;
            else if(xProgress == 10 && yProgress == 3) color <= 3'b100;
            else if(xProgress == 12 && yProgress == 3) color <= 3'b110;
            else if(xProgress == 15 && yProgress == 3) color <= 3'b100;
            else if(xProgress == 20 && yProgress == 3) color <= 3'b000;
            else if(xProgress == 8 && yProgress == 4) color <= 3'b100;
            else if(xProgress == 10 && yProgress == 4) color <= 3'b110;
            else if(xProgress == 11 && yProgress == 4) color <= 3'b100;
            else if(xProgress == 12 && yProgress == 4) color <= 3'b110;
            else if(xProgress == 16 && yProgress == 4) color <= 3'b100;
            else if(xProgress == 17 && yProgress == 4) color <= 3'b110;
            else if(xProgress == 19 && yProgress == 4) color <= 3'b100;
            else if(xProgress == 21 && yProgress == 4) color <= 3'b000;
            else if(xProgress == 7 && yProgress == 5) color <= 3'b100;
            else if(xProgress == 9 && yProgress == 5) color <= 3'b110;
            else if(xProgress == 10 && yProgress == 5) color <= 3'b100;
            else if(xProgress == 11 && yProgress == 5) color <= 3'b110;
            else if(xProgress == 12 && yProgress == 5) color <= 3'b100;
            else if(xProgress == 14 && yProgress == 5) color <= 3'b110;
            else if(xProgress == 17 && yProgress == 5) color <= 3'b100;
            else if(xProgress == 19 && yProgress == 5) color <= 3'b110;
            else if(xProgress == 20 && yProgress == 5) color <= 3'b100;
            else if(xProgress == 21 && yProgress == 5) color <= 3'b000;
            else if(xProgress == 6 && yProgress == 6) color <= 3'b100;
            else if(xProgress == 10 && yProgress == 6) color <= 3'b110;
            else if(xProgress == 11 && yProgress == 6) color <= 3'b111;
            else if(xProgress == 12 && yProgress == 6) color <= 3'b110;
            else if(xProgress == 13 && yProgress == 6) color <= 3'b100;
            else if(xProgress == 15 && yProgress == 6) color <= 3'b110;
            else if(xProgress == 18 && yProgress == 6) color <= 3'b100;
            else if(xProgress == 22 && yProgress == 6) color <= 3'b000;
            else if(xProgress == 6 && yProgress == 7) color <= 3'b100;
            else if(xProgress == 7 && yProgress == 7) color <= 3'b110;
            else if(xProgress == 9 && yProgress == 7) color <= 3'b111;
            else if(xProgress == 11 && yProgress == 7) color <= 3'b110;
            else if(xProgress == 15 && yProgress == 7) color <= 3'b100;
            else if(xProgress == 16 && yProgress == 7) color <= 3'b110;
            else if(xProgress == 19 && yProgress == 7) color <= 3'b100;
            else if(xProgress == 20 && yProgress == 7) color <= 3'b110;
            else if(xProgress == 22 && yProgress == 7) color <= 3'b100;
            else if(xProgress == 23 && yProgress == 7) color <= 3'b000;
            else if(xProgress == 5 && yProgress == 8) color <= 3'b100;
            else if(xProgress == 7 && yProgress == 8) color <= 3'b110;
            else if(xProgress == 8 && yProgress == 8) color <= 3'b111;
            else if(xProgress == 10 && yProgress == 8) color <= 3'b110;
            else if(xProgress == 15 && yProgress == 8) color <= 3'b100;
            else if(xProgress == 17 && yProgress == 8) color <= 3'b110;
            else if(xProgress == 19 && yProgress == 8) color <= 3'b100;
            else if(xProgress == 21 && yProgress == 8) color <= 3'b110;
            else if(xProgress == 22 && yProgress == 8) color <= 3'b100;
            else if(xProgress == 23 && yProgress == 8) color <= 3'b000;
            else if(xProgress == 5 && yProgress == 9) color <= 3'b100;
            else if(xProgress == 6 && yProgress == 9) color <= 3'b110;
            else if(xProgress == 8 && yProgress == 9) color <= 3'b111;
            else if(xProgress == 9 && yProgress == 9) color <= 3'b110;
            else if(xProgress == 16 && yProgress == 9) color <= 3'b100;
            else if(xProgress == 17 && yProgress == 9) color <= 3'b110;
            else if(xProgress == 20 && yProgress == 9) color <= 3'b100;
            else if(xProgress == 21 && yProgress == 9) color <= 3'b110;
            else if(xProgress == 23 && yProgress == 9) color <= 3'b100;
            else if(xProgress == 24 && yProgress == 9) color <= 3'b000;
            else if(xProgress == 5 && yProgress == 10) color <= 3'b100;
            else if(xProgress == 6 && yProgress == 10) color <= 3'b110;
            else if(xProgress == 11 && yProgress == 10) color <= 3'b100;
            else if(xProgress == 14 && yProgress == 10) color <= 3'b110;
            else if(xProgress == 16 && yProgress == 10) color <= 3'b100;
            else if(xProgress == 17 && yProgress == 10) color <= 3'b110;
            else if(xProgress == 20 && yProgress == 10) color <= 3'b100;
            else if(xProgress == 22 && yProgress == 10) color <= 3'b110;
            else if(xProgress == 23 && yProgress == 10) color <= 3'b100;
            else if(xProgress == 24 && yProgress == 10) color <= 3'b000;
            else if(xProgress == 4 && yProgress == 11) color <= 3'b100;
            else if(xProgress == 6 && yProgress == 11) color <= 3'b110;
            else if(xProgress == 10 && yProgress == 11) color <= 3'b100;
            else if(xProgress == 12 && yProgress == 11) color <= 3'b110;
            else if(xProgress == 13 && yProgress == 11) color <= 3'b100;
            else if(xProgress == 14 && yProgress == 11) color <= 3'b110;
            else if(xProgress == 16 && yProgress == 11) color <= 3'b100;
            else if(xProgress == 18 && yProgress == 11) color <= 3'b110;
            else if(xProgress == 21 && yProgress == 11) color <= 3'b100;
            else if(xProgress == 22 && yProgress == 11) color <= 3'b110;
            else if(xProgress == 23 && yProgress == 11) color <= 3'b100;
            else if(xProgress == 26 && yProgress == 11) color <= 3'b000;
            else if(xProgress == 3 && yProgress == 12) color <= 3'b100;
            else if(xProgress == 4 && yProgress == 12) color <= 3'b110;
            else if(xProgress == 5 && yProgress == 12) color <= 3'b100;
            else if(xProgress == 6 && yProgress == 12) color <= 3'b110;
            else if(xProgress == 7 && yProgress == 12) color <= 3'b100;
            else if(xProgress == 9 && yProgress == 12) color <= 3'b110;
            else if(xProgress == 10 && yProgress == 12) color <= 3'b100;
            else if(xProgress == 11 && yProgress == 12) color <= 3'b110;
            else if(xProgress == 13 && yProgress == 12) color <= 3'b100;
            else if(xProgress == 14 && yProgress == 12) color <= 3'b110;
            else if(xProgress == 17 && yProgress == 12) color <= 3'b100;
            else if(xProgress == 18 && yProgress == 12) color <= 3'b110;
            else if(xProgress == 21 && yProgress == 12) color <= 3'b100;
            else if(xProgress == 22 && yProgress == 12) color <= 3'b110;
            else if(xProgress == 23 && yProgress == 12) color <= 3'b100;
            else if(xProgress == 24 && yProgress == 12) color <= 3'b110;
            else if(xProgress == 25 && yProgress == 12) color <= 3'b100;
            else if(xProgress == 27 && yProgress == 12) color <= 3'b000;
            else if(xProgress == 3 && yProgress == 13) color <= 3'b100;
            else if(xProgress == 4 && yProgress == 13) color <= 3'b110;
            else if(xProgress == 5 && yProgress == 13) color <= 3'b100;
            else if(xProgress == 7 && yProgress == 13) color <= 3'b110;
            else if(xProgress == 9 && yProgress == 13) color <= 3'b100;
            else if(xProgress == 14 && yProgress == 13) color <= 3'b110;
            else if(xProgress == 17 && yProgress == 13) color <= 3'b100;
            else if(xProgress == 18 && yProgress == 13) color <= 3'b110;
            else if(xProgress == 21 && yProgress == 13) color <= 3'b100;
            else if(xProgress == 23 && yProgress == 13) color <= 3'b110;
            else if(xProgress == 26 && yProgress == 13) color <= 3'b100;
            else if(xProgress == 27 && yProgress == 13) color <= 3'b000;
            else if(xProgress == 4 && yProgress == 14) color <= 3'b100;
            else if(xProgress == 5 && yProgress == 14) color <= 3'b110;
            else if(xProgress == 7 && yProgress == 14) color <= 3'b100;
            else if(xProgress == 9 && yProgress == 14) color <= 3'b110;
            else if(xProgress == 11 && yProgress == 14) color <= 3'b100;
            else if(xProgress == 13 && yProgress == 14) color <= 3'b110;
            else if(xProgress == 14 && yProgress == 14) color <= 3'b100;
            else if(xProgress == 22 && yProgress == 14) color <= 3'b110;
            else if(xProgress == 26 && yProgress == 14) color <= 3'b100;
            else if(xProgress == 27 && yProgress == 14) color <= 3'b000;
            else if(xProgress == 5 && yProgress == 15) color <= 3'b100;
            else if(xProgress == 9 && yProgress == 15) color <= 3'b110;
            else if(xProgress == 25 && yProgress == 15) color <= 3'b100;
            else if(xProgress == 27 && yProgress == 15) color <= 3'b000;
            else if(xProgress == 8 && yProgress == 16) color <= 3'b100;
            else if(xProgress == 11 && yProgress == 16) color <= 3'b110;
            else if(xProgress == 24 && yProgress == 16) color <= 3'b100;
            else if(xProgress == 26 && yProgress == 16) color <= 3'b000;
            else if(xProgress == 10 && yProgress == 17) color <= 3'b100;
            else if(xProgress == 25 && yProgress == 17) color <= 3'b000;
        end 
        else if (selector == 2'b10) begin  //HH Hit
            if(xProgress == 0 && yProgress == 0) color <= 3'b000;
            else if(xProgress == 1 && yProgress == 1) color <= 3'b110;
            else if(xProgress == 3 && yProgress == 1) color <= 3'b000;
            else if(xProgress == 27 && yProgress == 1) color <= 3'b110;
            else if(xProgress == 28 && yProgress == 1) color <= 3'b000;
            else if(xProgress == 3 && yProgress == 2) color <= 3'b110;
            else if(xProgress == 5 && yProgress == 2) color <= 3'b000;
            else if(xProgress == 11 && yProgress == 2) color <= 3'b100;
            else if(xProgress == 16 && yProgress == 2) color <= 3'b000;
            else if(xProgress == 25 && yProgress == 2) color <= 3'b110;
            else if(xProgress == 27 && yProgress == 2) color <= 3'b000;
            else if(xProgress == 4 && yProgress == 3) color <= 3'b110;
            else if(xProgress == 6 && yProgress == 3) color <= 3'b000;
            else if(xProgress == 10 && yProgress == 3) color <= 3'b100;
            else if(xProgress == 12 && yProgress == 3) color <= 3'b110;
            else if(xProgress == 15 && yProgress == 3) color <= 3'b100;
            else if(xProgress == 20 && yProgress == 3) color <= 3'b000;
            else if(xProgress == 24 && yProgress == 3) color <= 3'b110;
            else if(xProgress == 26 && yProgress == 3) color <= 3'b000;
            else if(xProgress == 8 && yProgress == 4) color <= 3'b100;
            else if(xProgress == 10 && yProgress == 4) color <= 3'b110;
            else if(xProgress == 11 && yProgress == 4) color <= 3'b100;
            else if(xProgress == 12 && yProgress == 4) color <= 3'b110;
            else if(xProgress == 16 && yProgress == 4) color <= 3'b100;
            else if(xProgress == 17 && yProgress == 4) color <= 3'b110;
            else if(xProgress == 19 && yProgress == 4) color <= 3'b100;
            else if(xProgress == 21 && yProgress == 4) color <= 3'b000;
            else if(xProgress == 23 && yProgress == 4) color <= 3'b110;
            else if(xProgress == 25 && yProgress == 4) color <= 3'b000;
            else if(xProgress == 7 && yProgress == 5) color <= 3'b100;
            else if(xProgress == 9 && yProgress == 5) color <= 3'b110;
            else if(xProgress == 10 && yProgress == 5) color <= 3'b100;
            else if(xProgress == 11 && yProgress == 5) color <= 3'b110;
            else if(xProgress == 12 && yProgress == 5) color <= 3'b100;
            else if(xProgress == 14 && yProgress == 5) color <= 3'b110;
            else if(xProgress == 17 && yProgress == 5) color <= 3'b100;
            else if(xProgress == 19 && yProgress == 5) color <= 3'b110;
            else if(xProgress == 20 && yProgress == 5) color <= 3'b100;
            else if(xProgress == 21 && yProgress == 5) color <= 3'b000;
            else if(xProgress == 29 && yProgress == 5) color <= 3'b110;
            else if(xProgress == 1 && yProgress == 6) color <= 3'b000;
            else if(xProgress == 6 && yProgress == 6) color <= 3'b100;
            else if(xProgress == 10 && yProgress == 6) color <= 3'b110;
            else if(xProgress == 11 && yProgress == 6) color <= 3'b111;
            else if(xProgress == 12 && yProgress == 6) color <= 3'b110;
            else if(xProgress == 13 && yProgress == 6) color <= 3'b100;
            else if(xProgress == 15 && yProgress == 6) color <= 3'b110;
            else if(xProgress == 18 && yProgress == 6) color <= 3'b100;
            else if(xProgress == 22 && yProgress == 6) color <= 3'b000;
            else if(xProgress == 28 && yProgress == 6) color <= 3'b110;
            else if(xProgress == 29 && yProgress == 6) color <= 3'b000;
            else if(xProgress == 1 && yProgress == 7) color <= 3'b110;
            else if(xProgress == 3 && yProgress == 7) color <= 3'b000;
            else if(xProgress == 6 && yProgress == 7) color <= 3'b100;
            else if(xProgress == 7 && yProgress == 7) color <= 3'b110;
            else if(xProgress == 9 && yProgress == 7) color <= 3'b111;
            else if(xProgress == 11 && yProgress == 7) color <= 3'b110;
            else if(xProgress == 15 && yProgress == 7) color <= 3'b100;
            else if(xProgress == 16 && yProgress == 7) color <= 3'b110;
            else if(xProgress == 19 && yProgress == 7) color <= 3'b100;
            else if(xProgress == 20 && yProgress == 7) color <= 3'b110;
            else if(xProgress == 22 && yProgress == 7) color <= 3'b100;
            else if(xProgress == 23 && yProgress == 7) color <= 3'b000;
            else if(xProgress == 26 && yProgress == 7) color <= 3'b110;
            else if(xProgress == 29 && yProgress == 7) color <= 3'b000;
            else if(xProgress == 2 && yProgress == 8) color <= 3'b110;
            else if(xProgress == 4 && yProgress == 8) color <= 3'b000;
            else if(xProgress == 5 && yProgress == 8) color <= 3'b100;
            else if(xProgress == 7 && yProgress == 8) color <= 3'b110;
            else if(xProgress == 8 && yProgress == 8) color <= 3'b111;
            else if(xProgress == 10 && yProgress == 8) color <= 3'b110;
            else if(xProgress == 15 && yProgress == 8) color <= 3'b100;
            else if(xProgress == 17 && yProgress == 8) color <= 3'b110;
            else if(xProgress == 19 && yProgress == 8) color <= 3'b100;
            else if(xProgress == 21 && yProgress == 8) color <= 3'b110;
            else if(xProgress == 22 && yProgress == 8) color <= 3'b100;
            else if(xProgress == 23 && yProgress == 8) color <= 3'b000;
            else if(xProgress == 26 && yProgress == 8) color <= 3'b110;
            else if(xProgress == 27 && yProgress == 8) color <= 3'b000;
            else if(xProgress == 5 && yProgress == 9) color <= 3'b100;
            else if(xProgress == 6 && yProgress == 9) color <= 3'b110;
            else if(xProgress == 8 && yProgress == 9) color <= 3'b111;
            else if(xProgress == 9 && yProgress == 9) color <= 3'b110;
            else if(xProgress == 16 && yProgress == 9) color <= 3'b100;
            else if(xProgress == 17 && yProgress == 9) color <= 3'b110;
            else if(xProgress == 20 && yProgress == 9) color <= 3'b100;
            else if(xProgress == 21 && yProgress == 9) color <= 3'b110;
            else if(xProgress == 23 && yProgress == 9) color <= 3'b100;
            else if(xProgress == 24 && yProgress == 9) color <= 3'b000;
            else if(xProgress == 5 && yProgress == 10) color <= 3'b100;
            else if(xProgress == 6 && yProgress == 10) color <= 3'b110;
            else if(xProgress == 11 && yProgress == 10) color <= 3'b100;
            else if(xProgress == 14 && yProgress == 10) color <= 3'b110;
            else if(xProgress == 16 && yProgress == 10) color <= 3'b100;
            else if(xProgress == 17 && yProgress == 10) color <= 3'b110;
            else if(xProgress == 20 && yProgress == 10) color <= 3'b100;
            else if(xProgress == 22 && yProgress == 10) color <= 3'b110;
            else if(xProgress == 23 && yProgress == 10) color <= 3'b100;
            else if(xProgress == 24 && yProgress == 10) color <= 3'b000;
            else if(xProgress == 2 && yProgress == 11) color <= 3'b110;
            else if(xProgress == 3 && yProgress == 11) color <= 3'b000;
            else if(xProgress == 4 && yProgress == 11) color <= 3'b100;
            else if(xProgress == 6 && yProgress == 11) color <= 3'b110;
            else if(xProgress == 10 && yProgress == 11) color <= 3'b100;
            else if(xProgress == 12 && yProgress == 11) color <= 3'b110;
            else if(xProgress == 13 && yProgress == 11) color <= 3'b100;
            else if(xProgress == 14 && yProgress == 11) color <= 3'b110;
            else if(xProgress == 16 && yProgress == 11) color <= 3'b100;
            else if(xProgress == 18 && yProgress == 11) color <= 3'b110;
            else if(xProgress == 21 && yProgress == 11) color <= 3'b100;
            else if(xProgress == 22 && yProgress == 11) color <= 3'b110;
            else if(xProgress == 23 && yProgress == 11) color <= 3'b100;
            else if(xProgress == 26 && yProgress == 11) color <= 3'b000;
            else if(xProgress == 29 && yProgress == 11) color <= 3'b110;
            else if(xProgress == 2 && yProgress == 12) color <= 3'b000;
            else if(xProgress == 3 && yProgress == 12) color <= 3'b100;
            else if(xProgress == 4 && yProgress == 12) color <= 3'b110;
            else if(xProgress == 5 && yProgress == 12) color <= 3'b100;
            else if(xProgress == 6 && yProgress == 12) color <= 3'b110;
            else if(xProgress == 7 && yProgress == 12) color <= 3'b100;
            else if(xProgress == 9 && yProgress == 12) color <= 3'b110;
            else if(xProgress == 10 && yProgress == 12) color <= 3'b100;
            else if(xProgress == 11 && yProgress == 12) color <= 3'b110;
            else if(xProgress == 13 && yProgress == 12) color <= 3'b100;
            else if(xProgress == 14 && yProgress == 12) color <= 3'b110;
            else if(xProgress == 17 && yProgress == 12) color <= 3'b100;
            else if(xProgress == 18 && yProgress == 12) color <= 3'b110;
            else if(xProgress == 21 && yProgress == 12) color <= 3'b100;
            else if(xProgress == 22 && yProgress == 12) color <= 3'b110;
            else if(xProgress == 23 && yProgress == 12) color <= 3'b100;
            else if(xProgress == 24 && yProgress == 12) color <= 3'b110;
            else if(xProgress == 25 && yProgress == 12) color <= 3'b100;
            else if(xProgress == 27 && yProgress == 12) color <= 3'b000;
            else if(xProgress == 28 && yProgress == 12) color <= 3'b110;
            else if(xProgress == 1 && yProgress == 13) color <= 3'b000;
            else if(xProgress == 3 && yProgress == 13) color <= 3'b100;
            else if(xProgress == 4 && yProgress == 13) color <= 3'b110;
            else if(xProgress == 5 && yProgress == 13) color <= 3'b100;
            else if(xProgress == 7 && yProgress == 13) color <= 3'b110;
            else if(xProgress == 9 && yProgress == 13) color <= 3'b100;
            else if(xProgress == 14 && yProgress == 13) color <= 3'b110;
            else if(xProgress == 17 && yProgress == 13) color <= 3'b100;
            else if(xProgress == 18 && yProgress == 13) color <= 3'b110;
            else if(xProgress == 21 && yProgress == 13) color <= 3'b100;
            else if(xProgress == 23 && yProgress == 13) color <= 3'b110;
            else if(xProgress == 26 && yProgress == 13) color <= 3'b100;
            else if(xProgress == 27 && yProgress == 13) color <= 3'b000;
            else if(xProgress == 4 && yProgress == 14) color <= 3'b100;
            else if(xProgress == 5 && yProgress == 14) color <= 3'b110;
            else if(xProgress == 7 && yProgress == 14) color <= 3'b100;
            else if(xProgress == 9 && yProgress == 14) color <= 3'b110;
            else if(xProgress == 11 && yProgress == 14) color <= 3'b100;
            else if(xProgress == 13 && yProgress == 14) color <= 3'b110;
            else if(xProgress == 14 && yProgress == 14) color <= 3'b100;
            else if(xProgress == 22 && yProgress == 14) color <= 3'b110;
            else if(xProgress == 26 && yProgress == 14) color <= 3'b100;
            else if(xProgress == 27 && yProgress == 14) color <= 3'b000;
            else if(xProgress == 5 && yProgress == 15) color <= 3'b100;
            else if(xProgress == 9 && yProgress == 15) color <= 3'b110;
            else if(xProgress == 25 && yProgress == 15) color <= 3'b100;
            else if(xProgress == 27 && yProgress == 15) color <= 3'b000;
            else if(xProgress == 2 && yProgress == 16) color <= 3'b110;
            else if(xProgress == 4 && yProgress == 16) color <= 3'b000;
            else if(xProgress == 8 && yProgress == 16) color <= 3'b100;
            else if(xProgress == 11 && yProgress == 16) color <= 3'b110;
            else if(xProgress == 24 && yProgress == 16) color <= 3'b100;
            else if(xProgress == 26 && yProgress == 16) color <= 3'b000;
            else if(xProgress == 27 && yProgress == 16) color <= 3'b110;
            else if(xProgress == 29 && yProgress == 16) color <= 3'b000;
            else if(xProgress == 1 && yProgress == 17) color <= 3'b110;
            else if(xProgress == 3 && yProgress == 17) color <= 3'b000;
            else if(xProgress == 10 && yProgress == 17) color <= 3'b100;
            else if(xProgress == 25 && yProgress == 17) color <= 3'b000;
            else if(xProgress == 29 && yProgress == 17) color <= 3'b110;
            else if(xProgress == 1 && yProgress == 18) color <= 3'b000;
        end
    end

endmodule



/*
module part2(iResetn,iPlotBox,iBlack,iColour,iLoadX,iXY_Coord,iClock,oX,oY,oColour,oPlot,oDone);
   //specify input
   parameter X_SCREEN_PIXELS = 8'd160;
   parameter Y_SCREEN_PIXELS = 7'd120;
   input wire iResetn, iPlotBox, iBlack, iLoadX;
   input wire [2:0] iColour;
   input wire [6:0] iXY_Coord;
   input wire 	    iClock;
   output  [7:0] oX;       
   output  [6:0] oY;
   output  [2:0] oColour;     
   output  oPlot;       
   output  oDone;    

   helper u0(.iResetn(iResetn),.iPlotBox(iPlotBox),.iBlack(iBlack),
      .iColour(iColour), .iLoadX(iLoadX),.iXY_Coord(iXY_Coord),
      .clk(iClock),.oX(oX),.oY(oY), .oColour(oColour),
      .oPlot(oPlot),.oDone(oDone));
endmodule */