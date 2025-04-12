`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/12/2025 10:00:07 AM
// Design Name: 
// Module Name: SpriteMenu
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


module SpriteMenu(
    input [12:0] pixel_index,
    input [3:0] state,
    input btnL,
    input btnR,
    input clk,
    output [15:0] oled_data,
    output reg [1:0] sel = 2'b00
    );
    
    import sprites::*;
    
    localparam posY = 27;
    localparam posX = 32;
    
    wire [5:0] y;
    wire [6:0] x;
    wire [15:0] oledDataMenu;
    reg [15:0] oledDataSprite = 16'b0;
    reg [0:63] spriteData [2:0];
    reg [15:0] spriteColour [2:0];
    reg lastLeft = 1'b0;
    reg lastRight = 1'b0;
    
    initial begin
        spriteData[0] = ORANGE_SPRITE_LEFT_DATA;
        spriteData[1] = DINO_SPRITE_LEFT_DATA;
        spriteData[2] = CAT_SPRITE_LEFT_DATA;
        spriteColour[0] = 16'hFE40;
        spriteColour[1] = DINO_COLOUR;
        spriteColour[2] = CAT_COLOUR;
    end
    
    assign x = pixel_index % 96;
    assign y = pixel_index / 96;
    
    SpriteSelector sprSel (
        y,
        x,
        oledDataMenu
    );
    
    always @ (posedge clk) begin
        if ((btnL & ~lastLeft) && (state == 1)) begin
            sel <= sel - 1;
            if (sel == 3) sel <= 2'b10;
        end
        if ((btnR & ~lastRight) && (state == 1)) begin
            sel <= sel + 1;
            if (sel == 3) sel <= 2'b00;
        end
        
        lastLeft <= btnL;
        lastRight <= btnR;
        if (x >= posX && y >= posY && x <= posX + 31 && y <= posY + 31
            && spriteData[sel][((y - posY) >> 2) * 8 + ((x - posX) >> 2)]) begin
            oledDataSprite <= spriteColour[sel];
        end else begin
            oledDataSprite <= 16'b0;
        end
    end
    assign oled_data = oledDataSprite | oledDataMenu;
    
    
endmodule
