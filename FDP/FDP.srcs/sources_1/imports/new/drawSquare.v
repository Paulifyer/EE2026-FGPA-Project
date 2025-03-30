`timescale 1ns / 1ps

module drawSquare #(parameter SIZE=8)(
    input      [7:0]  x,
    input      [7:0]  y,
    input      [15:0] colour,
    input      [SIZE*SIZE-1:0] squareData,
    input      [12:0] cordinateIndex,
    output     [15:0] oledColour
);
    
    parameter WIDTH  = 96;
    parameter HEIGHT = 64;
    
    wire [7:0] cordY = cordinateIndex / WIDTH;
    wire [7:0] cordX = cordinateIndex % WIDTH;

    wire [7:0] squareX = cordX - x;
    wire [7:0] squareY = cordY - y;
    wire [7:0] squareIndex = (squareY * SIZE) + squareX;
    
    wire inSquare = (cordX >= x && cordX < x + SIZE) && 
                    (cordY >= y && cordY < y + SIZE);

    wire activeColour = inSquare && squareData[~squareIndex];
    
    assign oledColour = activeColour ? colour : 16'h0000;
    
endmodule