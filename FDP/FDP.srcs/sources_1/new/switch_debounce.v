`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 15.03.2025 00:45:51
// Design Name: 
// Module Name: switch_debounce
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


module switch_debounce(input clk, input [22:0] debound_count, input btn, output btn_state);
    reg cooldown = 0;
    reg [7:0] count = 0;
    reg released = 1;
    always @ (posedge clk) begin
        if (!btn)
            released = 1;
        if (cooldown && count < debound_count-1)
            count = count + 1;
        else if (count >= debound_count-1) begin
            cooldown = 0;
            count = 0;
        end
        if (btn && !cooldown) begin
            cooldown = 1;
            released = 0;
        end
    end
    assign btn_state = btn & released & ~cooldown;
endmodule
