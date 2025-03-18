`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03.03.2025 21:36:53
// Design Name: 
// Module Name: slow_clock
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module slow_clock(input clk, input [31:0] period, output reg slow_clock = 0);
    reg [24:0] count = 0;
    always @ (posedge clk) begin
        count <= (count == period/2-1) ? 0 : count + 1;
        slow_clock <= (count == 0) ? ~slow_clock : slow_clock ;
    end
endmodule
