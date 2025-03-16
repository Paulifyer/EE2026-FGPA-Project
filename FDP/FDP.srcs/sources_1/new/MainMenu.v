`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03/16/2025 06:53:21 PM
// Design Name: 
// Module Name: MainMenu
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


module MainMenu(
    input [12:0] pixel_index,
    input halfSecClock, state,
    output reg [15:0] oled_data
    );
    wire [7:0] X; wire [7:0] Y;
    assign X = pixel_index % 96;
    assign Y = pixel_index / 96;    
    reg [0:95] bitmap [0:63];
    reg [6:0] i;
    initial begin
        bitmap[0] =  96'h0001c006030000040000001f;
        bitmap[1] =  96'h0001c002030000040000000f;
        bitmap[2] =  96'h3ff80ff030387fc0fff0ffc3;
        bitmap[3] =  96'h3ffc1ff830787fe0fff0ffc3;
        bitmap[4] =  96'h381e383c3cf87078e000e060;
        bitmap[5] =  96'h381e383c3ff87038e000e060;
        bitmap[6] =  96'h3c1c383c3ff87038e000e060;
        bitmap[7] =  96'h3ff8383c33387fe0ffc0ffc0;
        bitmap[8] =  96'h3ff8383c33387fe0ffc0ffc0;
        bitmap[9] =  96'h381e383c30387038e000e060;
        bitmap[10] = 96'h381e383c30387038e000e071;
        bitmap[11] = 96'h381e383c30387038e000e060;
        bitmap[12] = 96'h3c1c383c30387078fff0e060;
        bitmap[13] = 96'h3ff81ff830387fe0fff0e060;
        bitmap[14] = 96'h000000000000000000000000;
        bitmap[15] = 96'h000000000000000000000000;
        bitmap[16] = 96'hc000f000c0c0000300000100;
        bitmap[17] = 96'hc000f000c0c0000300000100;
        bitmap[18] = 96'hffffffffffffffffffffffff;
        bitmap[19] = 96'hffffffffffffffffffffffff;
        bitmap[20] = 96'hffffffffffffffffffffffff;
        bitmap[21] = 96'hffffff80c0c0030381ffffff;
        bitmap[22] = 96'hffffff8080c0030100ffffff;
        bitmap[23] = 96'hffffff9c1c0ff0383c7fffff;
        bitmap[24] = 96'hffffff9c1c1ff83c3c7fffff;
        bitmap[25] = 96'hffffff9f3e1c3c3e3c7fffff;
        bitmap[26] = 96'hffffff9ffe1c3c3f3c7fffff;
        bitmap[27] = 96'hffffff9ffe1c3c3f3c7fffff;
        bitmap[28] = 96'hffffff9cde1c3c39fc7fffff;
        bitmap[29] = 96'hffffff9c1e1ffc38fc7fffff;
        bitmap[30] = 96'hffffff9c1e1ffc387c7fffff;
        bitmap[31] = 96'hffffff9c1e1ffc383c7fffff;
        bitmap[32] = 96'hffffff9c1e1c3c381c7fffff;
        bitmap[33] = 96'hffffff9c1e1c3c381c7fffff;
        bitmap[34] = 96'hffffff9c1e1c3c381c7fffff;
        bitmap[35] = 96'hffffff8000000000007fffff;
        bitmap[36] = 96'hffffff8000000000007fffff;
        bitmap[37] = 96'hffffffe020006000607fffff;
        bitmap[38] = 96'hffffffe020006000607fffff;
        bitmap[39] = 96'hffffffffffffffffffffffff;
        bitmap[40] = 96'hffffffffffffffffffffffff;
        bitmap[41] = 96'hffffffffffffffffffffffff;
        bitmap[42] = 96'hffffffffffffffffffffffff;
        bitmap[43] = 96'hffffffffffffffffffffffff;
        bitmap[44] = 96'hffffffffffffffffffffffff;
        bitmap[45] = 96'hffffffffffffffffffffffff;
        bitmap[46] = 96'hffffffffffffffffffffffff;
        bitmap[47] = 96'hffffffffffffffffffffffff;
        bitmap[48] = 96'hffffffffffffffffffffffff;
        bitmap[49] = 96'hfffffff8080810100fffffff;
        bitmap[50] = 96'hfffffff3e3e3c7c7c7ffffff;
        bitmap[51] = 96'hfffffff63186662187ffffff;
        bitmap[52] = 96'hfffffff60186662587ffffff;
        bitmap[53] = 96'hfffffff3e19667e59fffffff;
        bitmap[54] = 96'hfffffff03197e6259fffffff;
        bitmap[55] = 96'hfffffff6319666259fffffff;
        bitmap[56] = 96'hfffffff3e19666259fffffff;
        bitmap[57] = 96'hfffffff8041000041fffffff;
        bitmap[58] = 96'hfffffffc061880461fffffff;
        bitmap[59] = 96'hffffffffffffffffffffffff;
        bitmap[60] = 96'hffffffffffffffffffffffff;
        bitmap[61] = 96'hffffffffffffffffffffffff;
        bitmap[62] = 96'hffffffffffffffffffffffff;
        bitmap[63] = 96'hffffffffffffffffffffffff;
        
    end
    always @ (pixel_index, X, Y) begin
        if (~state) begin
            if ((X >= 24 && X <= 26 && Y >= 45 && Y <= 59) ||
                (X >= 24 && X <= 46 && Y >= 60 && Y <= 62) ||
                (X >= 49 && X <= 72 && Y >= 45 && Y <= 47) ||
                (X >= 70 && X <= 72 && Y >= 48 && Y <= 62))
                    oled_data = (halfSecClock) ? 16'b0 : 16'b1111111111111111;
            else if (bitmap[Y][X] == 1'b1) oled_data = 16'b1111111111111111;
            else oled_data = 16'b0;
        end
    end
endmodule
