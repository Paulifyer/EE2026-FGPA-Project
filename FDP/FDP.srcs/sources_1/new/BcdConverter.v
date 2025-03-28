`timescale 1ns / 1ps

module BcdConverter(
    input [15:0] score,
    output reg [3:0] digit0,
    output reg [3:0] digit1,
    output reg [3:0] digit2,
    output reg [3:0] digit3
);
    
    reg [15:0] temp;
    
    // Convert binary score to 4-digit BCD (assumes score < 10000)
    always @(*) begin
        temp   = score;
        digit3 = temp / 1000;
        temp   = temp % 1000;
        digit2 = temp / 100;
        temp   = temp % 100;
        digit1 = temp / 10;
        digit0 = temp % 10;
    end

endmodule
