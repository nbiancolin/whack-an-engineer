module getClock(clock);
    output reg clock;
    parameter SWITCHTIME = 500;
    initial begin 
        clock = 1; 
    end
    always begin
        #SWITCHTIME clock = ~clock;
    end
endmodule