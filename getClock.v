module getClock(clock);
    output reg clk
    parameter SWITCHTIME = 500;
    initial begin 
        clk = 1; 
    end
    always begin
        #SWITCHTIME clk = ~clk;
    end
endmodule