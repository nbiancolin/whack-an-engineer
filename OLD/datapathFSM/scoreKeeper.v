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