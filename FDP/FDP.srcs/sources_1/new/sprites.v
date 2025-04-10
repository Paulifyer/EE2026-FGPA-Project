`timescale 1ns / 1ps

// module main(...);
// ++import sprites::*;
// endmodule 

package sprites;
  // Orange sprite data
  parameter ORANGE_SPRITE_DATA = {
    8'b11000011, 8'b01100110, 8'b00111100, 8'b01111110, 8'b11011011, 8'b01111110, 8'b00100100
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
  parameter BRICK_COLOUR = 16'hF800;  // Red

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
  parameter DINO_COLOUR = 16'hFFE0;  // Yellow

  // Wall sprite data
  parameter WALL_SPRITE_DATA = {
    8'b11111111,
    8'b10000001,
    8'b10000001,
    8'b10000001,
    8'b10000001,
    8'b10000001,
    8'b10000001,
    8'b11111111
  };
  parameter WALL_COLOUR = 16'h001F;  // Blue

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
  parameter CAT_COLOUR = 16'h07E0;  // Green

  // Heart sprite data
  parameter HEART_SPRITE_DATA = {
    8'b01100110,
    8'b11111111,
    8'b11111111,
    8'b11111111,
    8'b11111111,
    8'b01111110,
    8'b00111100,
    8'b00011000
  };
  parameter HEART_RED = 16'hfa20;

  // Bomb sprite data
  parameter BOMB_SPRITE_DATA = {
    8'b00000000,
    8'b00001100,
    8'b00010000,
    8'b00111000,
    8'b01111100,
    8'b01111100,
    8'b01111100,
    8'b00111000
  };
  parameter BOMB_GREY = 16'ha554;
  parameter BOMB_ORANGE = 16'ha554;
endpackage
