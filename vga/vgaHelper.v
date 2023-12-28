module vgaHelper(iResetn, hhSelect, gameState, moleHit, clk, oX, oY, oColour, oPlot, oDone); //note: oDone does not need to be an output
    parameter X_SCREEN_PIXELS = 8'd160;
    parameter Y_SCREEN_PIXELS = 7'd120;
    parameter CLOCK_FREQ = 13'd50000000; //LATER match this with board freq
    input iResetn, clk, moleHit;  //(iresetn is [0])
    //moleHit goes to 1 when a mole is hit (handle in 'GAME')
    input [4:0] hhSelect; //Also one-hot encoding (switches SW[4:0])
    input [2:0] gameState;

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


    localparam  P_RST       = 3'd0,     //draws over initial screen (from mif or with plot algo) (should also reset ram ??)
                RST         = 3'd1,     //waiting for input to start game
                P_GAME      = 3'd2,     //plots full screen from ram 
                GAME        = 3'd3,     //waits for input
                W_RAM       = 3'd4,     //writes to ram
                P_GAME_OVER = 3'd5,     //plots the game over  
                R_RAM       = 3'd6,     //writes correct hard hats over the ram (TODO: Implement this)
                GAME_OVER   = 3'd7;     //waits for signal to go back to P_GAME

    localparam  HH_1 = 5'b00001, //one hot encoding since tested on switches
                HH_2 = 5'b00010, 
                HH_3 = 5'b00100,
                HH_4 = 5'b01000,
                HH_5 = 5'b10000;

    localparam  HH_STEADY = 3'b001,
                HH_READY = 3'b010,
                HH_HIT = 3'b100;
    
    reg [2:0] curState, nextState;
    reg [7:0] xProgress;        //counter
    reg [6:0] yProgress;

    wire [2:0] steadyCol, readyCol, hitCol, splashCol, gSteadyCol, gOverCol;
    reg [2:0] sel;
    reg flag;

    reg [15:0] counter;
    reg [15:0] vgaCounter;
	reg [14:0] address;
	
    reg wren;
    reg [2:0] data;

	reg [4:0] stoHHSelect;


    hh_steady h0(.address(address), .clock(clk), .q(steadyCol)); //reading from ram (technically ROM)
    hh_ready h1(.address(address), .clock(clk), .q(readyCol));
    hh_hit h2(.address(address), .clock(clk), .q(hitCol));
	
	splash g0(.address(address), .clock(clk), .q(splashCol));    
	g_steady g1(.address(address), .clock(clk), .data(oColour), .wren(wren), .q(gSteadyCol));  //writing changes to ram, only updating all changes 30 times a second (douuble buffering, so no tearing)
    gameOver g2(.address(address), .clock(clk), .q(gOverCol));
	
	
    always@(*) begin 
        case(curState)
        P_RST: 
            nextState <= oDone ? RST : P_RST;
        RST:
            nextState <= (gameState == 3'd2) ? P_GAME : RST;   //should this be STARTGAME or INGAME
		P_GAME:
			nextState <= oDone ? GAME : P_GAME;
		GAME: begin
            //go to game over if game state is game over
            if(gameState == 3'd4) nextState <= P_GAME_OVER;
            //if the counter reaches CLOCK_FREQ / 40, go to P_GAME (40 fps)
            else if(vgaCounter == CLOCK_FREQ / 40) nextState <= P_GAME;
            //if moleHit goes to 1, go to wRam
            else if(moleHit && !flag) nextState <= W_RAM;
            else if(!moleHit && flag) nextState <= W_RAM; //when it goes to 0, write back as steady
            //if hhSelect changes, go to wRam (separate counter gets set to 0 here)
            else if(stoHHSelect != hhSelect) nextState <= W_RAM;
            //if it has been 1 second (counter reaches clock_freq), and hhSelect is the same. write hhSelect to wRam
            else if(counter == 0) nextState <= W_RAM;
            //else stay same
            else nextState <= GAME;
        end
		W_RAM: 
            nextState <= oDone ? GAME : W_RAM;
        P_GAME_OVER:
            nextState <= oDone ? GAME_OVER : P_GAME_OVER;
        GAME_OVER:
            nextState <= (gameState == 3'd3) ? P_GAME : GAME_OVER;   //same, 3 or 2?
		  endcase
    end

	always@(posedge clk) begin
		if(iResetn) begin 
            curState <= P_RST;
            oX <= 0;
            oY <= 0;
			oDone <= 0;
			address <= 1;
            xProgress <= 0;
            yProgress <= 0;
			stoHHSelect <= 0;
			counter <= CLOCK_FREQ;
            flag <= 0;
            sel <= 0;
        end
		else begin
			curState <= nextState;
			case(curState)
			P_RST: begin  //reads colour from ROM
				oColour <= splashCol;
                address <= address +15'd1;
				if (!oDone) begin
                oPlot <= 1;  
                if (xProgress < X_SCREEN_PIXELS -1) begin
                    oX <= oX + 1; 
                    xProgress <= xProgress + 1;  
                end else begin
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
                    oX <= 0;
                    oY <= 0;
                    address <= 1;
                end
            end else begin
                oDone <= 1; 
            end
			end
			RST: address <= 0;//oDone <= 1'b1;//does anything happen here?
			P_GAME: begin //reads from ram
                oColour <= gSteadyCol;
                address <= address +1;
				if (!oDone) begin
                oPlot <= 1;  
                if (xProgress < X_SCREEN_PIXELS -1) begin
                    oX <= oX + 1; 
                    xProgress <= xProgress + 1;  
                end else begin
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
                    oX <= 0;
                    oY <= 0;
                    address <= 1;
                end
            end else begin
                oDone <= 1; 
            end
			end
			GAME: begin
                yProgress <= 0;
                counter <= counter +1;
                vgaCounter <= vgaCounter +1;
                 //go to game over if game state is game over
                if(gameState == 3'd4) begin //nextState <= P_GAME_OVER;
                    oX <= 0;
                    oY <= 0;
                    oDone <= 0;
                    counter <= 0;
                    vgaCounter <= 0;
                    address <= 1;
                    //other stuff here maybe I don't think so

                end
                //if the counter reaches CLOCK_FREQ / 40, go to P_GAME (40 fps)
                else if(vgaCounter == CLOCK_FREQ / 40) begin //nextState <= P_GAME;
                    oX <= 0;
                    oY <= 0;
                    oDone <= 0;
                    vgaCounter <= 0;
                    address <= 1;
                    
                    //other stuff?? its just drawing the ram so idk
                end


                //if moleHit goes to 1, go to wRam
                else if(moleHit && !flag) begin //nextState <= W_RAM;
                    sel <= HH_HIT;
                    flag <= 1;
                    //stoHHSelect <= hhSelect;
                    case(hhSelect) //decoding hhSelect
                    HH_1: begin  //(for now) assuming only one hh is selected at any given time
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
                else if(!moleHit && flag) begin
                    flag <= 0;
                    sel <= HH_STEADY;
                    case(hhSelect) //decoding hhSelect
                    HH_1: begin  //(for now) assuming only one hh is selected at any given time
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
                //if hhSelect changes, go to wRam (separate counter gets set to 0 here)
                else if(stoHHSelect != hhSelect) begin //nextState <= W_RAM;
                    sel <= HH_READY;
                    //stoHHSelect <= hhSelect;
                    case(hhSelect) //decoding hhSelect
                    HH_1: begin  //(for now) assuming only one hh is selected at any given time
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


               //end
                //if it has been 1 second (counter reaches clock_freq), write hhSelect to wRam
                else if(counter == 0) begin //nextState <= W_RAM;
                    counter <= CLOCK_FREQ;
                    sel <= HH_READY;
                    stoHHSelect <= hhSelect;
                    case(hhSelect) //decoding hhSelect
                    HH_1: begin  //(for now) assuming only one hh is selected at any given time
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
                else begin

				oDone <= 0;//does anything acc happen in this state
				yProgress <= 0;
				counter <= counter +1;
				stoHHSelect <= hhSelect;
				case(hhSelect) //decoding hhSelect
				HH_1: begin  //(for now) assuming only one hh is selected at any given time
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
            end
            W_RAM: begin
                case(sel)
                HH_STEADY: oColour <= steadyCol;
                HH_READY: oColour <= readyCol;
                HH_HIT: oColour <= hitCol;
                endcase
                oColour <= gSteadyCol;
                address <= oY * X_SCREEN_PIXELS + oX;
				if (!oDone) begin
                //oPlot <= 1;  
                wren <= 1;
                if (xProgress < X_HH -1) begin
                    oX <= oX + 1; 
                    xProgress <= xProgress + 1;  
                end else begin
                    oX <= oX - xProgress;  
                    xProgress <= 0; 
                    if (yProgress < Y_HH -1) begin
                        oY <= oY + 1;  
                        yProgress <= yProgress + 1; 
                    end
                end
                if (xProgress == (X_HH -1) && yProgress == (Y_HH -1)) begin
                    oDone <= 1;  
                    //oPlot <= 0;
                    wren <= 0;  
                    oX <= 0;
                    oY <= 0;
                    address <= 1;
                end
                end
            end
            //PLOT GAME OVER STATE HERE
			endcase
		end
	end


endmodule


