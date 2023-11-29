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
endmodule 

module helper(iResetn,iPlotBox,iBlack,iColour,iLoadX,iXY_Coord,clk,oX,oY,oColour,oPlot,oDone);
    parameter X_SCREEN_PIXELS = 8'd160;
    parameter Y_SCREEN_PIXELS = 7'd120;
    input iResetn, iPlotBox, iBlack, iLoadX;
    input [2:0] iColour;
    input [6:0] iXY_Coord;
    input clk;
    output reg [7:0] oX;      //transformed coordinates 
    output reg [6:0] oY;
    output reg [2:0] oColour;     
    output reg oPlot;       
    output reg oDone;  


    localparam  RESET        = 3'd0,
                LOADING      = 3'd1,
                DRAW_GAME    = 3'd2,
                PLOT         = 3'd3
                G_STEADY     = 3'd4,
                G_HIT        = 3'd5,
                G_RESET      = 3'd6;
    
    reg [2:0] curState, nextState;
    reg [7:0] Xsize;            //upper bound of counter
    reg [6:0] Ysize;
    reg [7:0] xProgress;        //counter
    reg [6:0] yProgress;

    reg [2:0] color;

    reg [15:0] counter;

    reg [1:0] selector; //used to select colours
    

    /*
    (RESET) -> reset all variables
    (LOADING) -> Clears screen (minus tape measure)
                                                                                (out) (DRAW_GAME) -> draws full game screen
    (PLOT) -> Does the plotting
    (G_STEADY) -> waits for one of 3 buttons to go to next state
    (G_HIT) -> draws the hat that has been hit
    (G_RESET) -> Draws hat back to original

    iBlack = start

    iLoadX = hit1
    iPlotBox = hit2
    iResetn = resetn


    Selector:
    00 - draw base screen
    01 - draw hh splash
    10 - draw hh outline
    */

    always@(*) begin
        case(curState)
        RESET: begin
            if(iBlack) nextState <= LOADING;
            //nextState <= iBlack ? LOADING ? RESET;
        end
        LOADING: 
            nextState <= oDone ? LOADING : PLOT;
        //DRAW_GAME:
            //nextState <= oDone ? G_STEADY : DRAW_GAME;
        //    nextState <= oDone ? LOADING: PLOT; //switches when nextState is released
        PLOT:
            nextState <= oDone ? G_STEADY : PLOT;
        G_STEADY: begin
            if(iLoadX) nextState <= G_HIT;
            else if (iPlotBox) nextState <= G_HIT;
            else if(iResetn) nextState <= RESET;
        end
        G_HIT:   
            nextState = iPlotBox ? G_HIT : PLOT; //switches on negedge
        G_RESET: 
            nextState = oDone ? G_STEADY : G_RESET;
        endcase
    end

    always@(posedge clk) begin
        if(!iResetn) curState <= RESET;
        else curState <= nextState;

        if(curState == LOADING) begin //do something
            //drawing full screen so
            oDone <= 0;
            oPlot <= 1;  
            //oColour <= 3'b000; 
            Xsize <= X_SCREEN_PIXELS - 1;
            Ysize <= Y_SCREEN_PIXELS - 1;  
            oX <= 0;
            oY <= 0;
            xProgress <= 0;
            yProgress <= 0;
            selector <= 2'b00
        end else
        //else if (curState == DRAW_GAME) begin

        //end else
        if(curState = PLOT) begin
            if (!oDone) begin
                oPlot <= 1;  
                //oColour <= color; 
                if (xProgress < Xsize) begin
                    oX <= oX + 1; 
                    xProgress <= xProgress + 1;  
                end else begin
                //if (xProgress == Xsize) begin
                    oX <= oX - xProgress;  
                    xProgress <= 0; 
                    if (yProgress < Ysize) begin
                        oY <= oY + 1;  
                        yProgress <= yProgress + 1; 
                    end
                end
                if (xProgress == Xsize && yProgress == Ysize) begin
                    oDone <= 1;  
                    oPlot <= 0;  
                    xSize <= 29; //xSize is for upper bound (these are now being set for hard-hat)
                    ySize <= 19;
                end
                //colors from python script go here
                //use switch // if statements to select which colour set


            end else begin
                oDone <= 1; 
            end

    

        end else
        if (curState == ) //pick up here
    end
    




endmodule