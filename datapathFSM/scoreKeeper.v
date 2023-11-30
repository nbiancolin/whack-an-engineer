module scoreKeeper (clock, scoreReset, moleHit, score);
    input clock;
    input scoreReset;
    input [2:0] hit;
    output reg [7:0] score;
    initial begin
        score = 5'b00000;
    end

    always @(posedge clock or posedge scoreReset) begin
        if (scoreReset) begin
            score <= 0;
        end else begin
            score <= score + 1;  //default, change it sto FSM with states later
        end
    end
endmodule