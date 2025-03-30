`timescale 1ns / 1ps

// module main(...);
// ++import sprites::*;
// endmodule 

package sprites;
    // Orange sprite data
    parameter ORANGE_SPRITE_DATA = {
        8'b11000011,
        8'b01100110,
        8'b00111100,
        8'b01111110,
        8'b11011011,
        8'b01111110,
        8'b00100100
    };

    // Brick sprite data
    parameter BRICK_SPRITE_DATA = {
        8'b00010000,
        8'b00010000,
        8'b11111111,
        8'b01000010,
        8'b01000010,
        8'b11111111,
        8'b00001000,
        8'b00001000
    };

    // Dino sprite data
    parameter DINO_SPRITE_DATA = {
        8'b00100100,
        8'b11111100,
        8'b11010100,
        8'b11111100,
        8'b00111101,
        8'b01111110,
        8'b00100100,
        8'b00100100
    };

    // Wall sprite data
    parameter WALL_SPRITE_DATA = {
        8'b11111110,
        8'b10000000,
        8'b10000000,
        8'b10000000,
        8'b10000000,
        8'b10000000,
        8'b10000000,
        8'b00000000
    };

    // Cat sprite data
    parameter CAT_SPRITE_DATA = {
        8'b00010001,
        8'b10011111,
        8'b10010101,
        8'b11111011,
        8'b11111111,
        8'b11111111,
        8'b10100101,
        8'b10100101
    };
endpackage