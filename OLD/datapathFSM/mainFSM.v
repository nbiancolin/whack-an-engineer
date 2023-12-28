module mainDataPath(clock, reset, startGame, userGameInput, molesGenerated, current_state);
//5 registers, each one 2 bits, 4 states, onscreen, hit, miss, offscreen
    input clock;
    input reset; 
    input startGame; 
    input [2:0] userGameInput; //which mole currently getting hit


    output reg [2:0] current_state;
    output wire [4:0] molesGenerated;

    reg [2:0] next_state;
    localparam  IDLE            = 3'd0,
                STARTSCREEN     = 3'd1,
                STARTGAME       = 3'd2,
                INGAME          = 3'd3,
                GAMEOVER        = 3'd4;

    reg gameOver; //if gameEnd and INGAME, then move onto GAMEOVER state

    //these are variables associated with startGame
    wire [5:0] currentCountDown;
    wire gameEnd; // when countDown hits 0, this enables
    wire [7:0] score; //score tracker
    //the following 2 will enable when first reach gameState
    wire [2:0] moleHit; // if user successfully hit a mole, display position of mole hit
    wire moleMiss; // if user missed the mole
    reg enableCountdown;
    reg scoreReset;
    //functions associated with startGame
    wire enableMolesRate;
    wire enableMolesGen;
    localparam generationRate = 1;
    RateDivider #(.CLOCK_FREQUENCY(50000000 / generationRate)) rateDU1(
        .ClockIn(clock),
        .Reset(scoreReset), 
        .enable(enableMolesRate)
    );
    assign enableMolesGen = (current_state == INGAME) ? enableMolesRate : 1'b0;
    generateMoles u1(.clock(clock), .reset(scoreReset), .enable(enableMolesGen), .molesGenerated(molesGenerated));
    matchLogic u0(.clock(clock), .molesGenerated(molesGenerated), .hit(userGameInput), .moleHit(moleHit), .moleMiss(moleMiss));
    
    countdownTimer u2(.clock(clock), .enableCountdown(enableCountdown), .scoreReset(scoreReset), .gameEnd(gameEnd), .currentCountDown(currentCountDown));
    scoreKeeper u3(.clock(clock), .scoreReset(scoreReset), .moleHit(moleHit), .score(score));

    //main FSM part of the code
    always @(posedge clock or posedge reset) begin
        if (reset) begin
            current_state <= IDLE;
        end
        else begin
            current_state <= next_state;
        end
    end

    //FSM: one hot state and state transitions
    always@(*) begin
        case(current_state)
        IDLE: 
            next_state = STARTSCREEN;
        STARTSCREEN:
            next_state = startGame? STARTGAME : STARTSCREEN;
        STARTGAME:
            //this stage allows for game to start, reset counter and score
            next_state = INGAME;
        INGAME:
            next_state = gameEnd? GAMEOVER: INGAME;
        GAMEOVER:
            next_state = reset? IDLE : GAMEOVER;
        default:
            next_state = IDLE;
        endcase
    end

    //state actions
    always@(posedge clock or posedge reset) begin
        if (reset) begin
            scoreReset <= 1;
            enableCountdown <= 0;
            gameOver <= 1;
        end else begin
            case(current_state) 
                STARTGAME: begin
                    enableCountdown <= 0;
                    scoreReset <= 1;
                    gameOver <= 1;
                end
                INGAME: begin
                    enableCountdown <= 1;
                    scoreReset <= 0;
                    gameOver <= 0;
                end
                GAMEOVER: begin
                    enableCountdown <= 0;
                    scoreReset <= 1;
                    gameOver <= 1;
                end
            endcase
            // A LOT OF CODE STILL NEEDS TO BE ADDED HERE
        end
    end
endmodule