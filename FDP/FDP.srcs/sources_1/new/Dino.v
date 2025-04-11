`timescale 1ns / 1ps

module Dino (
    input clk,
    input clk_1ms,              
    input [12:0] pixel_index,
    input en,
    output reg [15:0] pixel_data
);

    // Define colors
    parameter BLACK = 16'h0000;
    parameter PURPLE = 16'h7014;
    parameter RED = 16'hd82a;
    parameter PINK = 16'hd5be;
    parameter GREEN_BACKGROUND = 16'h0549;

    // Sprite data for the 8x8 pixel image (64 bits, 2 bits per pixel)
    reg [63:0] sprite_data = {
        // Each row is 16 bits (8 pixels * 2 bits per pixel)
        8'b00100100,
        8'b11111100,
        8'b11010100,
        8'b11111100,
        8'b00111101,
        8'b01111110,
        8'b00100100,
        8'b00100100
    };

    // Position constants
    parameter SPRITE_X = 44; // Adjusted X position for the sprite
    parameter SPRITE_Y = 28; // Adjusted Y position for the sprite

    // Convert pixel_index to x,y coordinates
    wire [6:0] x = pixel_index % 96;
    wire [6:0] y = pixel_index / 96;

// Pixel color output logic
always @* begin
    if (!en)
        pixel_data = BLACK;
    else if (x >= SPRITE_X && x < SPRITE_X + 8 && y >= SPRITE_Y && y < SPRITE_Y + 8) begin
        // Check if the current pixel is part of the sprite
        // Flip horizontally and vertically
        case (sprite_data[(7 - (y - SPRITE_Y)) * 8 + (7 - (x - SPRITE_X))])
            2'b00: pixel_data = BLACK;
            2'b01: pixel_data = PURPLE;
            2'b10: pixel_data = RED;
            2'b11: pixel_data = PINK;
            default: pixel_data = BLACK;
        endcase
    end else begin
        pixel_data = BLACK;
    end
end

endmodule