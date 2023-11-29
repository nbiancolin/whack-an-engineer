module mainDataPath(clock, reset, startGame, userGameInput);
    input clock;
    input reset; //from Jason
    input startGame; //startGame //from Jason
    input [2:0] userGameInput; //which mole currently getting hit //from Jason

    wire gameOver;

    reg [4:0] molesGenerated;
    wire moleMiss;

    reg [2:0] current_state, next_state;
    localparam  IDLE            = 3'd0,
                STARTSCREEN     = 3'd1,
                STARTGAME       = 3'd2,
                GAMEOVER        = 3'd4,

    matchLogic u0(clock, molesGenerated, hit, moleHit, moleMiss);
    generateMoles u1(clock, molesGenerated);


    always @(posedge clock or posedge reset) begin
        if (reset) begin
            current_state <= IDLE;
        end
        else begin
            current_state <= next_state;
        end
    end

    //FSM: one hot state
    always@(*) begin
        case(current_state)
        IDLE: 
            next_state = START_SCREEN;
        START_SCREEN:
            next_state = startGame? STARTGAME : START_SCREEN;
        STARTGAME:
            next_state = gameOver? GAMEOVER : STARTGAME;
        GAMEOVER:
            next_state = reset? IDLE : GAMEOVER;
        default:
            next_state = IDLE;
        endcase
    end

    always@(posedge clock)begin
        //logic later
    end
endmodule