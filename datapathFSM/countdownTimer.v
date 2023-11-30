module countdownTimer (
    input clock,
    input enableCountdown,
    input scoreReset,
    output gameEnd,
    output [5:0] currentCountDown
);
    wire reachedOneSec;

    RateDivider #(.CLOCK_FREQUENCY(50000000)) div0 (
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
#(parameter CLOCK_FREQUENCY = 50000000)
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