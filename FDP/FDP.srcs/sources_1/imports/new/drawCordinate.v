`timescale 1ns / 1ps

module drawCordinate (
    input [12:0] cordinateIndex,
    input [7:0] userX,
    input [7:0] userY,
    input BOMB1_en,
    input BOMB2_en,
    input [7:0] botX,
    input [7:0] botY,
    input [95:0] wall_tiles,
    input [95:0] breakable_tiles,
    input [7:0] BOMB1_X,
    input [7:0] BOMB1_Y,
    input [7:0] BOMB2_X,
    input [7:0] BOMB2_Y,
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
  wire [2:0] localX = pixelX % TILE_WIDTH;
  wire [2:0] localY = pixelY % TILE_HEIGHT;

  wire isWall = wall_tiles[tileIndex];
  wire isBreakable = breakable_tiles[tileIndex];
  
  wire [2:0] localX = pixelX % TILE_WIDTH; // IDKY but duplicating this fixes the orientation problem for objects
  wire [2:0] localY = pixelY % TILE_HEIGHT;
  wire [5:0] tilePixelIndex = localY * TILE_WIDTH + localX;
  
  // Determine active sprite pixel for wall and breakable using sprites data.
  wire wallActive = isWall && (WALL_SPRITE_DATA[tilePixelIndex]);
  wire brickActive = isBreakable && (BRICK_SPRITE_DATA[tilePixelIndex]);

  // Calculate if the current pixel matches any bomb's position (player or enemy)
  wire isBomb;
  wire isBOMB1 = BOMB1_en ? (pixelX >= BOMB1_X && pixelX < (BOMB1_X + TILE_WIDTH)) &&
                     (pixelY >= BOMB1_Y && pixelY < (BOMB1_Y + TILE_HEIGHT)) : 0;
  wire isBOMB2 = BOMB2_en ? (pixelX >= BOMB2_X && pixelX < (BOMB2_X + TILE_WIDTH)) &&
                    (pixelY >= BOMB2_Y && pixelY < (BOMB2_Y + TILE_HEIGHT)) : 0;

  assign isBomb = isBOMB1 || isBOMB2;

  parameter BLACK_COLOUR = 16'h0000;  // Black

  // Assign color based on tile type: bomb has highest priority.
  assign objectColour = ~wallActive & isWall ? WALL_COLOUR : 
                        (~brickActive & isBreakable ? BRICK_COLOUR : BLACK_COLOUR);

  // Instantiate drawSquare for user and bot blocks
  drawSquare #(8) userSquare (
      .x(userX),
      .y(userY),
      .colour(CAT_COLOUR),
      .squareData(CAT_SPRITE_DATA),
      .cordinateIndex(cordinateIndex),
      .oledColour(userSquareColour)
  );

  drawSquare #(8) botSquare (
      .x(botX),
      .y(botY),
      .colour(DINO_COLOUR),
      .squareData(DINO_SPRITE_DATA),
      .cordinateIndex(cordinateIndex),
      .oledColour(botSquareColour)
  );

  drawSquare #(8) bombSquare_1 (
      .x(BOMB1_X),
      .y(BOMB1_Y),
      .colour(BOMB_GREY),
      .squareData(BOMB_SPRITE_DATA),
      .cordinateIndex(cordinateIndex),
      .oledColour(bombSquareColour_1)
  );

  drawSquare #(8) bombSquare_2 (
      .x(BOMB2_X),
      .y(BOMB2_Y),
      .colour(BOMB_ORANGE),
      .squareData(BOMB_SPRITE_DATA),
      .cordinateIndex(cordinateIndex),
      .oledColour(bombSquareColour_2)
  );

  // Combine elements with priority: bot, user, then wall
  assign oledColour = botSquareColour | userSquareColour | 
                     (BOMB1_en ? bombSquareColour_1 : BLACK_COLOUR) | 
                     (BOMB2_en ? bombSquareColour_2 : BLACK_COLOUR) | 
                     objectColour;
endmodule
