module generateMoles (clock, gameStart, molesGenerated);
    input clock;
    input gameStart;
    output reg [4:0] molesGenerated;

    always@(posedge clock) begin
        if (gameStart) begin
            molesGenerated = 5'b01001;
        end else begin
            molesGenerated = 5'b00000;
        end
    end
endmodule