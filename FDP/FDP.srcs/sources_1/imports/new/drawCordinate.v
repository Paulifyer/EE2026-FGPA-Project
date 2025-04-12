`timescale 1ns / 1ps

module drawCordinate (
    input [12:0] cordinateIndex,
    input [6:0] user_index,
    input [6:0] bot_index,
    input [95:0] wall_tiles,
    input [95:0] breakable_tiles,
    input [95:0] explosion_display,
    input [95:0] powerup_tiles,
    input [41:0] bomb_indices, 
    input [5:0] bomb_en,
    input [2:0] user_direction,
    input [2:0] bot_direction,
    input user_dead,
    input bot_dead,
    input [1:0] sel, //sprite selection
    output [15:0] oledColour
);

  import sprites::*;

  parameter TILE_WIDTH = 8;  // 96/12 = 8 pixels per tile width
  parameter TILE_HEIGHT = 8;  // 64/8 = 8 pixels per tile height
  parameter GRID_WIDTH = 12;
  parameter GRID_HEIGHT = 8;

  wire [15:0] userSquareColour;
  wire [15:0] botSquareColour;
  wire [15:0] bombSquareColour_1;
  wire [15:0] bombSquareColour_2;
  wire [15:0] bombSquareColour_3;
  wire [15:0] bombSquareColour_4;
  wire [15:0] bombSquareColour_5;
  wire [15:0] bombSquareColour_6;
  wire [15:0] objectColour;

  // Calculate current pixel coordinates
  wire [6:0] pixelX = cordinateIndex % 96;
  wire [6:0] pixelY = cordinateIndex / 96;

  // Calculate which tile the current pixel belongs to
  wire [3:0] tileX = pixelX / TILE_WIDTH;
  wire [3:0] tileY = pixelY / TILE_HEIGHT;
  wire [6:0] tileIndex = (tileY * GRID_WIDTH) + tileX;

  // Calculate local coordinates within an 8x8 tile
  wire [4:0] localX = pixelX % TILE_WIDTH;
  wire [4:0] localY = pixelY % TILE_HEIGHT;

//   wire [2:0] localX = pixelX % TILE_WIDTH; // IDKY but duplicating this fixes the orientation problem for objects
//   wire [2:0] localY = pixelY % TILE_HEIGHT;

  wire isWall = wall_tiles[tileIndex];
  wire isBreakable = breakable_tiles[tileIndex];
  wire isPowerup = powerup_tiles[tileIndex];
  wire exploded = explosion_display[tileIndex];
  
  wire [5:0] tilePixelIndex = localY * TILE_WIDTH + localX;
  
  // Determine active sprite pixel for wall and breakable using sprites data.
  wire wallActive = isWall && (WALL_SPRITE_DATA[tilePixelIndex]);
  wire brickActive = isBreakable && (BRICK_SPRITE_DATA[tilePixelIndex]);
  wire powerupActive = isPowerup && (POWERUP_BOMBUP_SPRITE_DATA[tilePixelIndex]);
  wire explodeActive = exploded && (EXPLOSION_TRAIL_SPRITE_DATA[tilePixelIndex]);
  
  // Extract bomb indices directly from the input
  wire [6:0] bomb_index_1 = bomb_indices[6:0];
  wire [6:0] bomb_index_2 = bomb_indices[13:7];
  wire [6:0] bomb_index_3 = bomb_indices[20:14];
  wire [6:0] bomb_index_4 = bomb_indices[27:21];
  wire [6:0] bomb_index_5 = bomb_indices[34:28];
  wire [6:0] bomb_index_6 = bomb_indices[41:35];
  
  parameter BLACK_COLOUR = 16'h0000;  // Black
                        
  // Assign color based on tile type: bomb has highest priority.
  assign objectColour = ~wallActive & isWall ? WALL_COLOUR : 
                        ~brickActive & isBreakable ? BRICK_COLOUR : 
                        ~powerupActive & isPowerup ? POWERUP_BACKGROUND_GREEN : 
                        ~explodeActive & exploded ? EXPLOSION_ORANGE : 
                        BLACK_COLOUR;

  //To let users choose which sprite to play with
  reg [63:0] spriteDataLeft [2:0];
  reg [63:0] spriteDataRight [2:0];
  reg [15:0] spriteColour [2:0];
  initial begin
          spriteDataLeft[0] = ORANGE_SPRITE_LEFT_DATA;
          spriteDataLeft[1] = DINO_SPRITE_LEFT_DATA;
          spriteDataLeft[2] = CAT_SPRITE_LEFT_DATA;
          spriteDataRight[0] = ORANGE_SPRITE_RIGHT_DATA;
          spriteDataRight[1] = DINO_SPRITE_RIGHT_DATA;
          spriteDataRight[2] = CAT_SPRITE_RIGHT_DATA;
          spriteColour[0] = 16'hFE40;
          spriteColour[1] = DINO_COLOUR;
          spriteColour[2] = CAT_COLOUR;
  end
  
  // Instantiate drawSquare for user and bot blocks with index-based approach
  drawSquare #(8) userSquare (
      .tile_index(user_index),
      .colour(user_dead == 1? TOMBSTONE_GREY : spriteColour[sel]),
      .squareData(user_dead == 1? TOMBSTONE_SPRITE_DATA : 
                 (user_direction == 1 || user_direction == 4)? spriteDataLeft[sel] : spriteDataRight[sel]),
      .cordinateIndex(cordinateIndex),
      .oledColour(userSquareColour)
  );

  drawSquare #(8) botSquare (
      .tile_index(bot_index),
      .colour(user_dead == 1? TOMBSTONE_GREY : DINO_COLOUR),
      .squareData(bot_dead == 1? TOMBSTONE_SPRITE_DATA : 
                 (bot_direction == 1 || bot_direction == 4)? DINO_SPRITE_LEFT_DATA : DINO_SPRITE_RIGHT_DATA),
      .cordinateIndex(cordinateIndex),
      .oledColour(botSquareColour)
  );

  drawSquare #(8) bombSquare_1 (
      .tile_index(bomb_index_1),
      .colour(spriteColour[sel]),
      .squareData(BOMB_SPRITE_DATA),
      .cordinateIndex(cordinateIndex),
      .oledColour(bombSquareColour_1)
  );

  drawSquare #(8) bombSquare_2 (
      .tile_index(bomb_index_2),
      .colour(BOMB_GREY),
      .squareData(BOMB_SPRITE_DATA),
      .cordinateIndex(cordinateIndex),
      .oledColour(bombSquareColour_2)
  );

  drawSquare #(8) bombSquare_3 (
      .tile_index(bomb_index_3),
      .colour(BOMB_GREY),
      .squareData(BOMB_SPRITE_DATA),
      .cordinateIndex(cordinateIndex),
      .oledColour(bombSquareColour_3)
  );

  drawSquare #(8) bombSquare_4 (
      .tile_index(bomb_index_4),
      .colour(BOMB_ORANGE),
      .squareData(BOMB_SPRITE_DATA),
      .cordinateIndex(cordinateIndex),
      .oledColour(bombSquareColour_4)
  );

  drawSquare #(8) bombSquare_5 (
      .tile_index(bomb_index_5),
      .colour(BOMB_GREY),
      .squareData(BOMB_SPRITE_DATA),
      .cordinateIndex(cordinateIndex),
      .oledColour(bombSquareColour_5)
  );

  drawSquare #(8) bombSquare_6 (
      .tile_index(bomb_index_6),
      .colour(BOMB_ORANGE),
      .squareData(BOMB_SPRITE_DATA),
      .cordinateIndex(cordinateIndex),
      .oledColour(bombSquareColour_6)
  );

  // Combine elements with priority: bot, user, then wall
  assign oledColour = botSquareColour | userSquareColour | 
                     (bomb_en[0] ? bombSquareColour_1 : BLACK_COLOUR) | 
                     (bomb_en[1] ? bombSquareColour_2 : BLACK_COLOUR) | 
                     (bomb_en[2] ? bombSquareColour_3 : BLACK_COLOUR) | 
                     (bomb_en[3] ? bombSquareColour_4 : BLACK_COLOUR) | 
                     (bomb_en[4] ? bombSquareColour_5 : BLACK_COLOUR) | 
                     (bomb_en[5] ? bombSquareColour_6 : BLACK_COLOUR) | 
                     objectColour;
endmodule
