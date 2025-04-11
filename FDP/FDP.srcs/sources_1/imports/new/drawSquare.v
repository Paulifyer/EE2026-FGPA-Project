`timescale 1ns / 1ps

module drawSquare #(parameter SIZE=8)(
    input      [6:0]  tile_index,
    input      [15:0] colour,
    input      [SIZE*SIZE-1:0] squareData,
    input      [12:0] cordinateIndex,
    output     [15:0] oledColour
);
    
    parameter WIDTH  = 96;
    parameter HEIGHT = 64;
    parameter GRID_WIDTH = 12;
    parameter TILE_WIDTH = 8;
    parameter TILE_HEIGHT = 8;
    
    // Calculate x, y from tile_index
    wire [6:0] tileX = (tile_index % GRID_WIDTH) * TILE_WIDTH;
    wire [6:0] tileY = (tile_index / GRID_WIDTH) * TILE_HEIGHT;
    
    wire [7:0] cordY = cordinateIndex / WIDTH;
    wire [7:0] cordX = cordinateIndex % WIDTH;

    wire [7:0] squareX = cordX - tileX;
    wire [7:0] squareY = cordY - tileY;
    wire [7:0] squareIndex = (squareY * SIZE) + squareX;
    
    wire inSquare = (cordX >= tileX && cordX < tileX + SIZE) && 
                    (cordY >= tileY && cordY < tileY + SIZE);

    wire activeColour = inSquare && squareData[~squareIndex];
    
    assign oledColour = activeColour ? colour : 16'h0000;
    
endmodule