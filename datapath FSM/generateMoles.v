module generateMoles (clock, enable, molesGenerated);
    input clock;
    input gameStart;
    input enable;
    output reg [4:0] molesGenerated;

    generateFunction gen(.clock(clock), .enable(enable), .molesGenerated(molesgenerated)); //5'b00000 means no generated
endmodule