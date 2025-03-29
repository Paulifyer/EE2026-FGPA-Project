`timescale 1ns / 1ps

module Cat (
    input clk,
    input clk_1ms,              
    input [12:0] pixel_index,  // Current pixel being processed
    input en,              // Enable signal (when correct password entered)
    output reg [15:0] pixel_data  // Output color data for OLED
);

// Define colors
    parameter BLACK = 16'h0000;
    parameter YELLOW = 16'hf5a0;
    parameter YELLOW_LIGHT = 16'hf5a3;
    parameter YELLOW_DARK = 16'hb3e3;
    parameter GREEN_BACKGROUND = 16'h0549;

    // Sprite data for the 8x8 pixel image (64 bits, 2 bits per pixel)
    reg [63:0] sprite_data = {
        // Each row is 16 bits (8 pixels * 2 bits per pixel)
        8'b00010001,
        8'b10011111,
        8'b10010101,
        8'b11111011,
        8'b11111111,
        8'b11111111,
        8'b10100101,
        8'b10100101
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
            2'b01: pixel_data = YELLOW_LIGHT;
            2'b10: pixel_data = YELLOW_DARK;
            2'b11: pixel_data = YELLOW;
            default: pixel_data = BLACK; // Default
        endcase
    end else begin
        pixel_data = BLACK; // Default background color
    end
end

endmodule