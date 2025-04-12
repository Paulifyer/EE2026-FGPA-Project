`timescale 1ns / 1ps

// module main(...);
// ++import sprites::*;
// endmodule 

package sprites;
  // Orange sprite data [FACE LEFT]
  parameter ORANGE_SPRITE_LEFT_DATA = {
        8'b11000011,
        8'b01100110,
        8'b00111100,
        8'b01111110,
        8'b10101111,
        8'b11111111,
        8'b01011110,
        8'b00100100
  };
  
// Orange sprite data [FACE RIGHT]
  parameter ORANGE_SPRITE_RIGHT_DATA = {
        8'b11000011,
        8'b01100110,
        8'b00111100,
        8'b01111110,
        8'b11110101,
        8'b11111111,
        8'b01111010,
        8'b00100100
  };

  // Dino sprite data [FACE LEFT]
  parameter DINO_SPRITE_LEFT_DATA = {
      8'b00100100,
      8'b11111100,
      8'b11010100,
      8'b11111100,
      8'b00111101,
      8'b01111110,
      8'b00100100,
      8'b00100100
  };
  
  // Dino sprite data [FACE RIGHT]
  parameter DINO_SPRITE_RIGHT_DATA = {
      8'b00100100,
      8'b00111111,
      8'b00101011,
      8'b00111111,
      8'b10111100,
      8'b01111110,
      8'b00100100,
      8'b00100100
  };
  parameter DINO_COLOUR = 16'hFFE0;  // Yellow
  
    // Cat sprite data [FACE LEFT]
  parameter CAT_SPRITE_LEFT_DATA = {
      8'b10001000,
      8'b11111001,
      8'b10101001,
      8'b11011111,
      8'b11111111,
      8'b11111111,
      8'b10100101,
      8'b10100101
  };
  
// Cat sprite data [FACE RIGHT]
  parameter CAT_SPRITE_RIGHT_DATA = {
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
  parameter DAMAGED_RED = 16'hf800;  // USED IN BACKGROUND OF CHARACTERS WHEN TAKING DMG FOR 1s
  parameter REVIVE_YELLOW = 16'hff28;// USED IN BACKGROUND OF CHARACTER WHEN THEY REVIVE FOR 1s
  
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
  parameter BOMB_ORANGE = 16'hfa20;
  
  // Tombstone sprite data
  parameter TOMBSTONE_SPRITE_DATA = {  // REPLACES CHARACTERS WHEN THEY DIE
      8'b00000000,
      8'b00111110,
      8'b00110110,
      8'b00100010,
      8'b00110110,
      8'b00110110,
      8'b00111110,
      8'b01111111
  };
  parameter TOMBSTONE_GREY = 16'h8c0f;
  
  // Explosion CENTER sprite data
  parameter EXPLOSION_CENTER_SPRITE_DATA = {  // REPLACES BOMB WHEN THEY EXPLODE FOR 1s
      8'b10011001,
      8'b01011010,
      8'b00111100,
      8'b11111111,
      8'b11111111,
      8'b00111100,
      8'b01011010,
      8'b10011001
  };
  parameter EXPLOSION_ORANGE = 16'hfac0;
  
  // Explosion TRAIL sprite data
  parameter EXPLOSION_TRAIL_SPRITE_DATA = {  // EXPLOSION TRAIL VERTICALLY AND HORIZONTAL FROM BOMB
      8'b00000000,
      8'b00111110,
      8'b00110110,
      8'b00100010,
      8'b00110110,
      8'b00110110,
      8'b00111110,
      8'b01111111
  };
  
  // Powerup: Bombup sprite data
  parameter POWERUP_BOMBUP_SPRITE_DATA = {  // POWERUP FOR BOMBUP
      8'b00111000, //INVERTED TEMP FIX
      8'b01111100,
      8'b01111100,
      8'b01111100,
      8'b00111000,
      8'b00010000,
      8'b00001100,
      8'b00000000
  
//      8'b00000000, // ORIGINAL
//      8'b00001100,
//      8'b00010000,
//      8'b00111000,
//      8'b01111100,
//      8'b01111100,
//      8'b01111100,
//      8'b00111000
  };
  parameter POWERUP_BACKGROUND_GREEN = 16'h5660;
  parameter POWERUP_BOMBUP_GREY = 16'ha554;    
  
  // Powerup: Push sprite data
  parameter POWERUP_PUSH_SPRITE_DATA = {  // POWERUP FOR PUSH ABILITY
      8'b11001100, // INVERTED TEMP FIX
      8'b10001000,
      8'b01001001,
      8'b01110001,
      8'b01111111,
      8'b01110001,
      8'b00011001,
      8'b00011000

//      8'b00011000, // ORIGINAL
//      8'b00011001,
//      8'b01110001,
//      8'b01111111,
//      8'b01110001,
//      8'b01001001,
//      8'b10001000,
//      8'b11001100
  };
  parameter POWERUP_PUSH_PURPLE = 16'h7014;   
  
  // Powerup: Healthup sprite data
  parameter POWERUP_HEALTHUP_SPRITE_DATA = {  // POWERUP FOR HEALTHUP
      8'b00011000, // INVERTED TEMP FIX
      8'b00111100,
      8'b01111110,
      8'b11111111,
      8'b11111111,
      8'b11111111,
      8'b11100111,
      8'b01100110
  
//      8'b01100110, // ORIGINAL
//      8'b11111111,
//      8'b11111111,
//      8'b11111111,
//      8'b11111111,
//      8'b01111110,
//      8'b00111100,
//      8'b00011000
  }; 
  parameter POWERUP_HEALTH_RED = 16'hd0e4; 
  
  // Powerup: Reducetimer sprite data
  parameter POWERUP_REDUCETIMER_SPRITE_DATA = {  // POWERUP FOR REDUCETIMER
      8'b00001110, // INVERTED TEMP FIX
      8'b00100010,
      8'b01110010,
      8'b11111010,
      8'b00100010,
      8'b00100010,
      8'b00111110,
      8'b00000000
      
//      8'b00000000, // ORIGINAL
//      8'b00111110,
//      8'b00100010,
//      8'b00100010,
//      8'b11111010,
//      8'b01110010,
//      8'b00100010,
//      8'b00001110
  };   
  parameter POWERUP_REDUCETIME_WHITE = 16'hffff;    
  
  // Powerup: Bombrange sprite data
  parameter POWERUP_BOMBRANGE_SPRITE_DATA = {  // POWERUP FOR BOMBRANGE
      8'b00001100,
      8'b01100110,
      8'b00110011,
      8'b11111001,
      8'b11111001,
      8'b00110011,
      8'b01100110,
      8'b00001100
  };
  parameter POWERUP_BOMBRANGE_ORANGE = 16'hfa20; 
endpackage
