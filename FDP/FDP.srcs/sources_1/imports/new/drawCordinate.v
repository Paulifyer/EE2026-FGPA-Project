`timescale 1ns / 1ps

module drawCordinate (
    input [12:0] cordinateIndex,
    input [7:0] userX,
    input [7:0] userY,
    input bomb_en,
    input bomb_en_enemy,
    input [7:0] botX,
    input [7:0] botY,
    input [95:0] wall_tiles,
    input [95:0] breakable_tiles,
    input [7:0] bombX,
    input [7:0] bombY,
    input [7:0] bomb_enemy_x,
    input [7:0] bomb_enemy_y,
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
  wire isPlayerBomb = bomb_en ? (pixelX >= bombX && pixelX < (bombX + TILE_WIDTH)) &&
                     (pixelY >= bombY && pixelY < (bombY + TILE_HEIGHT)) : 0;
  wire isEnemyBomb = bomb_en_enemy ? (pixelX >= bomb_enemy_x && pixelX < (bomb_enemy_x + TILE_WIDTH)) &&
                    (pixelY >= bomb_enemy_y && pixelY < (bomb_enemy_y + TILE_HEIGHT)) : 0;

  assign isBomb = isPlayerBomb || isEnemyBomb;

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
      .x(bombX),
      .y(bombY),
      .colour(BOMB_GREY),
      .squareData(BOMB_SPRITE_DATA),
      .cordinateIndex(cordinateIndex),
      .oledColour(bombSquareColour_1)
  );

  drawSquare #(8) bombSquare_2 (
      .x(bomb_enemy_x),
      .y(bomb_enemy_y),
      .colour(BOMB_ORANGE),
      .squareData(BOMB_SPRITE_DATA),
      .cordinateIndex(cordinateIndex),
      .oledColour(bombSquareColour_2)
  );

  // Combine elements with priority: bot, user, then wall
  assign oledColour = botSquareColour | userSquareColour | 
                     (bomb_en ? bombSquareColour_1 : BLACK_COLOUR) | 
                     (bomb_en_enemy ? bombSquareColour_2 : BLACK_COLOUR) | 
                     objectColour;
endmodule
