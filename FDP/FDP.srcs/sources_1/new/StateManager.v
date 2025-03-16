`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03/17/2025 02:14:50 AM
// Design Name: 
// Module Name: StateManager
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


module StateManager(
    input btnC,
    input clk,
    output reg state = 1'b0
    );
    reg lastInput = 1'b0;
       always @ (posedge clk) begin
           if ((btnC & ~lastInput) && state == 1'b0)
              state = 1'b1;
           lastInput = btnC;
       end
endmodule
