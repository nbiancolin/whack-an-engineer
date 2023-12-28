module hex_decoder(c, display);
    input[3:0] c; //input [9:0] SW;
    output[7:0] display;

    //inverse of expected output due to common anode
    assign display[0] = ~c[3] & ~c[2] & ~c[1] & c[0] | 
                        ~c[3] & c[2] & ~c[1] & ~c[0] | 
                        c[3] & ~c[2] & c[1] & c[0] |
                        c[3] & c[2] & ~c[1] & c[0];
    assign display[1] = ~c[3] & c[2] & ~c[1] & c[0] | 
                        ~c[3] & c[2] & c[1] & ~c[0] | 
                        c[3] & ~c[2] & c[1] & c[0] | 
                        c[3] & c[2] & ~c[1] & ~c[0] | 
                        c[3] & c[2] & c[1] & ~c[0] | 
                        c[3] & c[2] & c[1] & c[0];
    assign display[2] = ~c[3] & ~c[2] & c[1] & ~c[0] | 
                        c[3] & c[2] & ~c[1] & ~c[0] | 
                        c[3] & c[2] & c[1] & ~c[0] | 
                        c[3] & c[2] & c[1] & c[0];
    assign display[3] = ~c[3] & ~c[2] & ~c[1] & c[0] | 
                        ~c[3] & c[2] & ~c[1] & ~c[0] | 
                        ~c[3] & c[2] & c[1] & c[0] | 
                        c[3] & ~c[2] & c[1] & ~c[0] | 
                        c[3] & c[2] & c[1] & c[0];
    assign display[4] = ~c[3] & ~c[2] & ~c[1] & c[0] | 
                        ~c[3] & ~c[2] & c[1] & c[0] | 
                        ~c[3] & c[2] & ~c[1] & ~c[0] | 
                        ~c[3] & c[2] & ~c[1] & c[0] | 
                        ~c[3] & c[2] & c[1] & c[0] | 
                        c[3] & c[2] & ~c[1] & c[0];
    assign display[5] = ~c[3] & ~c[2] & ~c[1] & c[0] |
                         ~c[3] & ~c[2] & c[1] & ~c[0] | 
                         ~c[3] & ~c[2] & c[1] & c[0] | 
                        ~c[3] & c[2] & c[1] & c[0] | 
                        c[3] & c[2] & ~c[1] & c[0];
    assign display[6] = ~c[3] & ~c[2] & ~c[1] & ~c[0] | 
                        ~c[3] & ~c[2] & ~c[1] & c[0] | 
                        ~c[3] & c[2] & c[1] & c[0] | 
                        c[3] & c[2] & ~c[1] & ~c[0];

endmodule
