`timescale 1ns / 1ps

module drawCordinate (
    input  [12:0] cordinateIndex,
    input  [ 7:0] greenX,
    input  [ 7:0] greenY,
    input  [ 7:0] yellowX,
    input  [ 7:0] yellowY,
    input  [95:0] wall_tiles,
    input  [95:0] breakable_tiles,
    input  [95:0] bomb_tiles,
    output [15:0] oledColour
);

  parameter black  = 16'h0000;
  parameter red    = 16'hF800;
  parameter white  = 16'hFFFF;
  parameter green  = 16'h07E0;
  parameter blue   = 16'h001F;
  parameter yellow = 16'hFFE0;

  parameter TILE_WIDTH  = 8;  // 96/12 = 8 pixels per tile width
  parameter TILE_HEIGHT = 8;  // 64/8 = 8 pixels per tile height
  parameter GRID_WIDTH  = 12;
  parameter GRID_HEIGHT = 8;

  wire [15:0] greenSquareColour;
  wire [15:0] yellowSquareColour;  // new wire for yellow square
  wire [15:0] objectColour;

  // Calculate current pixel coordinates
  wire [6:0] pixelX = cordinateIndex % 96;
  wire [6:0] pixelY = cordinateIndex / 96;

  // Calculate which tile the current pixel belongs to
  wire [3:0] tileX = pixelX / TILE_WIDTH;
  wire [3:0] tileY = pixelY / TILE_HEIGHT;
  wire [6:0] tileIndex = (tileY * GRID_WIDTH) + tileX;

  wire isWall = wall_tiles[tileIndex];
  wire isBreakable = breakable_tiles[tileIndex];
  wire isBomb = bomb_tiles[tileIndex];

  // Assign color based on tile type
  assign objectColour = isWall ? blue : (isBreakable ? white : (isBomb ? red : black));

  // Instantiate drawSquare for green and yellow blocks
  drawSquare greenSquare (
      .x(greenX),
      .y(greenY),
      .size(8),
      .colour(green),
      .cordinateIndex(cordinateIndex),
      .oledColour(greenSquareColour)
  );

  drawSquare yellowSquare (
      .x(yellowX),
      .y(yellowY),
      .size(8),
      .colour(yellow),
      .cordinateIndex(cordinateIndex),
      .oledColour(yellowSquareColour)
  );

  // Combine elements with priority: yellow, green, then wall
  assign oledColour = yellowSquareColour | greenSquareColour | objectColour;
endmodule
