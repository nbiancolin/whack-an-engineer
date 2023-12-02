module helper2(iResetn,iPlotBox,iBlack,iColour,iLoadX,iXY_Coord,clk,oX,oY,oColour,oPlot,oDone);
   parameter X_SCREEN_PIXELS = 8'd160;
   parameter Y_SCREEN_PIXELS = 7'd120;
   input iResetn, iPlotBox, iBlack, iLoadX;
   input [2:0] iColour;
   input [6:0] iXY_Coord;
   input clk;
   output reg [7:0] oX;       
   output reg [6:0] oY;
   output reg [2:0] oColour;     
   output reg oPlot;       
   output reg oDone;    

   
   reg [2:0] current_state, next_state;
   localparam  IDLE          = 3'd0,
               LOAD_X        = 3'd1,
               LOAD_Y        = 3'd2,
               PLOT          = 3'd4,
               CLEAR         = 3'd5;
   reg [7:0] Xsize;
   reg [6:0] Ysize;
   reg [8:0] xProgress;
   reg [7:0] yProgress;

   reg [2:0] color;


   always@(*) begin
      case(current_state)
      IDLE: begin
      if (iBlack) begin
        next_state = CLEAR;
      end
         else begin
         next_state = iLoadX? LOAD_X : IDLE;
         end
      end
      LOAD_X:
         next_state = iPlotBox? LOAD_Y : LOAD_X;
      LOAD_Y:
         next_state = iPlotBox? LOAD_Y : PLOT;
      PLOT:
         next_state = oDone? IDLE : PLOT;
      CLEAR:
         next_state = iBlack? CLEAR : PLOT;
      default:
         next_state = IDLE;
      endcase
   end

   always@(posedge clk) begin
      if (!iResetn) begin
         current_state = IDLE;
      end
      else begin
         current_state = next_state;
      end
   
      if (current_state == LOAD_X & iLoadX) begin
         xProgress <= 0;
         oX <= {1'b0, iXY_Coord}; 
      end
      else if (current_state == LOAD_Y) begin
         yProgress <= 0;
         oY <= iXY_Coord;
         oDone <= 0;
         color <= iColour;
         Xsize <= 3;
         Ysize <= 3;
      end
        else if (current_state == PLOT) begin
            if (!oDone) begin
                oPlot <= 1;  
                oColour <= color; 
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
                end
            end else begin
                oDone <= 1; 
            end
        end
        else if (current_state == CLEAR) begin
            oDone <= 0;
            oPlot <= 1;  
            oColour <= 3'b000; 
            Xsize <= X_SCREEN_PIXELS - 1;
            Ysize <= Y_SCREEN_PIXELS - 1;  
            oX <= 0;
            oY <= 0;
            xProgress <= 0;
            yProgress <= 0;
            
            //if (oX < Xsize) begin
            //    oX <= oX+1;
            //end else if (oY < Ysize) begin
            //    oX <= 0; 
            //    oY <= oY + 1; 
            //end else begin
            //    oDone <= 1; 
            //    oPlot <= 0;  
            //end
        end
   end

endmodule






module helper(iResetn,iPlotBox,iBlack,iColour,iLoadX,iXY_Coord,clk,oX,oY,oColour,oPlot,oDone);
   parameter X_SCREEN_PIXELS = 8'd160;
   parameter Y_SCREEN_PIXELS = 7'd120;
   input iResetn, iPlotBox, iBlack, iLoadX;
   input [2:0] iColour;
   input [6:0] iXY_Coord;
   input clk;
   output reg [7:0] oX;       
   output reg [6:0] oY;
   output reg [2:0] oColour;     
   output reg oPlot;       
   output reg oDone;    

   
   reg [2:0] current_state, next_state;
   localparam  IDLE          = 3'd0,
               LOAD_X        = 3'd1,
               LOAD_Y        = 3'd2,
               PLOT          = 3'd4,
               CLEAR         = 3'd5;
   reg [7:0] Xsize;
   reg [6:0] Ysize;
   reg [8:0] xProgress;
   reg [7:0] yProgress;

   reg [2:0] color;


   always@(*) begin
      case(current_state)
      IDLE: begin
      if (iBlack) begin
        next_state = CLEAR;
      end
         else begin
         next_state = iLoadX? LOAD_X : IDLE;
         end
      end
      LOAD_X:
         next_state = iPlotBox? LOAD_Y : LOAD_X;
      LOAD_Y:
         next_state = iPlotBox? LOAD_Y : PLOT;
      PLOT:
         next_state = oDone? IDLE : PLOT;
      CLEAR:
         next_state = iBlack? CLEAR : PLOT;
      default:
         next_state = IDLE;
      endcase
   end

   always@(posedge clk) begin
      if (!iResetn) begin
         current_state = IDLE;
      end
      else begin
         current_state = next_state;
      end
   
      if (current_state == LOAD_X & iLoadX) begin
         xProgress <= 0;
         oX <= {1'b0, iXY_Coord}; 
      end
      else if (current_state == LOAD_Y) begin
         yProgress <= 0;
         oY <= iXY_Coord;
         oDone <= 0;
         color <= iColour;
         Xsize <= 3;
         Ysize <= 3;
      end
        else if (current_state == PLOT) begin
            if (!oDone) begin
                oPlot <= 1;  
                oColour <= color; 
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
                end
            end else begin
                oDone <= 1; 
            end
        end
        else if (current_state == CLEAR) begin
            oDone <= 0;
            oPlot <= 1;  
            oColour <= 3'b000; 
            Xsize <= X_SCREEN_PIXELS - 1;
            Ysize <= Y_SCREEN_PIXELS - 1;  
            oX <= 0;
            oY <= 0;
            xProgress <= 0;
            yProgress <= 0;
            
            //if (oX < Xsize) begin
            //    oX <= oX+1;
            //end else if (oY < Ysize) begin
            //    oX <= 0; 
            //    oY <= oY + 1; 
            //end else begin
            //    oDone <= 1; 
            //    oPlot <= 0;  
            //end
        end
   end

endmodule

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