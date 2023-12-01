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
    RateDivider #(.CLOCK_FREQUENCY(10 / generationRate)) rateDU1(
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

//takes in which position has been hit (keybord input), and generated hitpoints
module matchLogic(clock, molesGenerated, hit, moleHit, moleMiss);
    input clock;
    //5 moles in total
    //each binary bit represents if a mole is generated. 
    //for example 01001 means the first and fourth are 
    input [4:0] molesGenerated;
    //can only hit one mole at a time
    //000 means no hit, 001 = first mole, 110 = fifth mole
    input [2:0] hit;

    //if a mole is hit. 1 means first hole mole is hit. 5 means fifth hole mole hit
    output reg [2:0] moleHit;
    //mole miss will give 1 if hit a hole where mole does not exist
    output reg moleMiss;


    //use a bitmask appraoch to store the hit states
    //previous functions should make sure only 1 hit at a time
    reg [4:0] hitMask;

    always @(hit) begin
        case(hit)
            3'b000: hitMask = 5'b00000; //no hits
            3'b001: hitMask = 5'b00001; //first mole hit
            3'b010: hitMask = 5'b00010;
            3'b011: hitMask = 5'b00100;
            3'b100: hitMask = 5'b01000;
            3'b101: hitMask = 5'b10000; //fifth mole hit
            default: hitMask = 5'b00000;
        endcase
    end

    //update output variables here
    always @(posedge clock) begin
        if ((molesGenerated & hitMask) == 0) begin 
            moleMiss <= (molesGenerated & hitMask) == 0 && hitMask? 1 : 0;
            moleHit <= 0;
            //something still wrong with moleHit, not reverting
        end else begin
            //else would be ran for successful mole hit 
            moleMiss <= 0;
            moleHit <= hit;
        end
    end
endmodule


module scoreKeeper (clock, scoreReset, moleHit, score);
    input clock;
    input scoreReset;
    input [2:0] moleHit;
    output reg [7:0] score;

    initial begin
        score = 8'b00000000;
    end

    always @(posedge clock or posedge scoreReset) begin
        if (scoreReset) begin
            score <= 0;
        end else if (moleHit > 0) begin
            score <= score + 1;  //default, change it sto FSM with states later
        end
    end
endmodule



module generateMoles (clock, reset, enable, molesGenerated);
    input clock;
    input enable;
    input reset;
    output [4:0] molesGenerated;
    // need to do something that clocks the enable, saves moles Generated as 1. 
    pseudo_rng gen(.clock(clock), .reset(reset), .generateEn(enable), .output_data(molesGenerated));
endmodule

/*
module pseudo_rng(clock, reset, generateEn, output_data);
	// pseudo rng relying on fast clocks
	input clock, reset, generateEn;
	output reg [4:0] output_data;
	
	reg [2:0] temp_data;
	parameter uppermax = $clog2(10000000);
	reg [uppermax -1:0] counter;
	
	always@(posedge clock) begin
		if (reset) begin
			counter <= 0;
			temp_data <= 0;
		end 
		else begin
			if (counter < 10000000 && counter >= 0)
				counter <= counter + 1;
			else
				counter <= 0;
		end
	end
	
	always@(posedge generateEn) begin
		temp_data = counter % 5; // 0-4
		
		case(temp_data) // one hot encoding
			3'b000: output_data <= 5'b00001;
			3'b001: output_data <= 5'b00010;
			3'b010: output_data <= 5'b00100;
			3'b011: output_data <= 5'b01000;
			3'b100: output_data <= 5'b10000;
			default: output_data <= 5'b00000;
		endcase
    end
endmodule
*/

module pseudo_rng(clock, reset, generateEn, output_data);
    input clock, reset, generateEn;
    output reg [4:0] output_data;

    reg [2:0] temp_data;
    parameter uppermax = $clog2(10000000);
    reg [uppermax -1:0] counter;

    always @(posedge clock or posedge reset) begin
        if (reset) begin
            counter <= 0;
            output_data <= 5'b00000;
        end else begin
            if (counter < 10000000 - 1) // counter to go from 0 to 9999999
                counter <= counter + 1;
            else
                counter <= 0;

            // This is where we check if generateEn is high and update output_data
            if (generateEn) begin
                temp_data <= counter [2:0]; // Taking the 3 LSBs for the RNG
                case(temp_data) // one hot encoding
                    3'b000: output_data <= 5'b00001;
                    3'b001: output_data <= 5'b00010;
                    3'b010: output_data <= 5'b00100;
                    3'b011: output_data <= 5'b01000;
                    3'b100: output_data <= 5'b10000;
                    3'b011: output_data <= 5'b00100;
                    3'b110: output_data <= 5'b10010;
                    3'b101: output_data <= 5'b01000;
                    3'b111: output_data <= 5'b00001;
                    default: output_data <= 5'b00000;
                endcase
            end
        end
    end
endmodule


module countdownTimer (
    input clock,
    input enableCountdown,
    input scoreReset,
    output gameEnd,
    output [5:0] currentCountDown
);
    wire reachedOneSec;

    RateDivider #(.CLOCK_FREQUENCY(50)) div0 (
        .ClockIn(clock),
        .Reset(scoreReset),
        .enable(reachedOneSec)
    );

    counter cnt0(
        .clock(clock),
        .enableCountdown(reachedOneSec && enableCountdown), 
        .reset(scoreReset),
        .gameEnd(gameEnd),
        .currentCountDown(currentCountDown)
    );
endmodule

module counter (
    input clock,
    input enableCountdown,
    input reset,
    output reg gameEnd,
    output reg [5:0] currentCountDown
);
    initial begin
        currentCountDown = 5;  
        gameEnd = 0;
    end

    always @(posedge clock or posedge reset) begin
        if (reset) begin
            //reasign
            currentCountDown <= 30;  
            gameEnd <= 0;

        end else if (enableCountdown && currentCountDown > 0) begin
            currentCountDown <= currentCountDown - 1;

            if (currentCountDown == 1) begin
                gameEnd <= 1;  
            end
        end
    end
endmodule

module RateDivider 
#(parameter CLOCK_FREQUENCY = 10)
(
    input ClockIn,
    input Reset,
    output enable
);
    reg [27:0] internalCount;
    always @(posedge ClockIn or posedge Reset) begin

        if (Reset || internalCount == 0) begin

            internalCount <= CLOCK_FREQUENCY - 1;
        end else begin
            internalCount <= internalCount - 1;
        end
    end
    assign enable = (internalCount == 0) ? 1'b1 : 1'b0;
endmodule
