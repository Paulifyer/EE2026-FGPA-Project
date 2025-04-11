`timescale 1ns / 1ps

module drawCordinate (
    input [12:0] cordinateIndex,
    input [6:0] user_index,
    input [6:0] bot_index,
    input [95:0] wall_tiles,
    input [95:0] breakable_tiles,
    input [13:0] bomb_indices,
    input [1:0] bomb_en,
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
  
  wire [5:0] tilePixelIndex = localY * TILE_WIDTH + localX;
  
  // Determine active sprite pixel for wall and breakable using sprites data.
  wire wallActive = isWall && (WALL_SPRITE_DATA[tilePixelIndex]);
  wire brickActive = isBreakable && (BRICK_SPRITE_DATA[tilePixelIndex]);
  
  // Extract bomb indices directly from the input
  wire [6:0] bomb_index_1 = bomb_indices[6:0];
  wire [6:0] bomb_index_2 = bomb_indices[13:7];

  parameter BLACK_COLOUR = 16'h0000;  // Black

  // Assign color based on tile type: bomb has highest priority.
  assign objectColour = ~wallActive & isWall ? WALL_COLOUR : 
                        (~brickActive & isBreakable ? BRICK_COLOUR : BLACK_COLOUR);

  // Instantiate drawSquare for user and bot blocks with index-based approach
  drawSquare #(8) userSquare (
      .tile_index(user_index),
      .colour(CAT_COLOUR),
      .squareData(CAT_SPRITE_LEFT_DATA),
      .cordinateIndex(cordinateIndex),
      .oledColour(userSquareColour)
  );

  drawSquare #(8) botSquare (
      .tile_index(bot_index),
      .colour(DINO_COLOUR),
      .squareData(DINO_SPRITE_LEFT_DATA),
      .cordinateIndex(cordinateIndex),
      .oledColour(botSquareColour)
  );

  drawSquare #(8) bombSquare_1 (
      .tile_index(bomb_index_1),
      .colour(BOMB_GREY),
      .squareData(BOMB_SPRITE_DATA),
      .cordinateIndex(cordinateIndex),
      .oledColour(bombSquareColour_1)
  );

  drawSquare #(8) bombSquare_2 (
      .tile_index(bomb_index_2),
      .colour(BOMB_ORANGE),
      .squareData(BOMB_SPRITE_DATA),
      .cordinateIndex(cordinateIndex),
      .oledColour(bombSquareColour_2)
  );

  // Combine elements with priority: bot, user, then wall
  assign oledColour = botSquareColour | userSquareColour | 
                     (bomb_en[0] ? bombSquareColour_1 : BLACK_COLOUR) | 
                     (bomb_en[1] ? bombSquareColour_2 : BLACK_COLOUR) | 
                     objectColour;
endmodule
