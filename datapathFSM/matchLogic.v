//takes in which position has been hit (keybord input), and generated hitpoints
module matchLogic(clock,molesGenerated, hit, moleHit, moleMiss);
    input clock;
    //5 moles in total
    //each binary bit represents if a mole is generated. 
    //for example 01001 means the first and fourth are 
    input molesGenerated[4:0];
    //can only hit one mole at a time
    //000 means no hit, 001 = first mole, 110 = fifth mole
    input hit[2:0];

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
            3'b000: hitMask = 5'b00001; //first mole hit
            3'b000: hitMask = 5'b00010;
            3'b000: hitMask = 5'b00100;
            3'b000: hitMask = 5'b01000;
            3'b000: hitMask = 5'b10000; //fifth mole hit
            default: hitMask = 5'b00000;
        endcase
    end

    //update output variables here
    always @(posedge clock) begin
        if ((molesGenerated & hitMask) == 0) begin 
            //that means either missed or not hit at all
            moleMiss <= hitMask? 0 : 1;
            moleHit <= 0;
        end 
        else begin
            //else would be ran for successful mole hit 
            moleMiss <= 0;
            moleHit <= hit;
        end
    end
endmodule