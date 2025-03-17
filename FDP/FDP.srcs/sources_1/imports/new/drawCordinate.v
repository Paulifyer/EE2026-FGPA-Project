`timescale 1ns / 1ps

module drawCordinate(
    input  [12:0] cordinateIndex, 
    input  [7:0]  greenX,
    input  [7:0]  greenY,
    input  [7:0]  yellowX,        // added yellowX input
    input  [7:0]  yellowY,        // added yellowY input
    input  [95:0] wall_tiles,
    input  [95:0] bomb_tiles,
    output [15:0] oledColour);
    
    parameter black = 16'h0000;
    parameter red   = 16'hF800;
    parameter green = 16'h07E0;
    parameter blue  = 16'h001F;
    parameter yellow= 16'hFFE0;    // new yellow color
    
    parameter TILE_WIDTH = 8;  // 96/12 = 8 pixels per tile width
    parameter TILE_HEIGHT = 8; // 64/8 = 8 pixels per tile height
    parameter GRID_WIDTH = 12;
    parameter GRID_HEIGHT = 8;
    
    wire [15:0] greenSquareColour;
    wire [15:0] yellowSquareColour;   // new wire for yellow square
    wire [15:0] wallsColour;
    
    // Calculate current pixel coordinates
    wire [6:0] pixelX = cordinateIndex % 96;
    wire [6:0] pixelY = cordinateIndex / 96;
    
    // Calculate which tile the current pixel belongs to
    wire [3:0] tileX = pixelX / TILE_WIDTH;
    wire [3:0] tileY = pixelY / TILE_HEIGHT;
    wire [6:0] tileIndex = (tileY * GRID_WIDTH) + tileX;
    
    // Check if current pixel is in a wall tile
    wire isWall = (tileX < GRID_WIDTH && tileY < GRID_HEIGHT) ? wall_tiles[tileIndex] : 0;
    wire isBomb = (tileX < GRID_WIDTH && tileY < GRID_HEIGHT) ? bomb_tiles[tileIndex] : 0;
    
    // Assign wall color if the pixel is in a wall tile
    assign wallsColour = isWall ? blue : isBomb ? red : black;
    
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
    assign oledColour = yellowSquareColour | greenSquareColour | wallsColour;
endmodule
