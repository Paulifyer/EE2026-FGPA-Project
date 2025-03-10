`timescale 1ns / 1ps

module drawSquare (
    input      [7:0]  x,
    input      [7:0]  y,
    input      [7:0]  size,
    input      [15:0] colour,
    input      [12:0] cordinateIndex,
    output     [15:0] oledColour
);
    
    parameter WIDTH  = 96;
    parameter HEIGHT = 64;
    
    wire [7:0] cordY = cordinateIndex / WIDTH;
    wire [7:0] cordX = cordinateIndex % WIDTH;
    
    wire inSquare = (cordX >= x && cordX < x + size) && 
                    (cordY >= y && cordY < y + size);
    
    assign oledColour = inSquare ? colour : 16'h0000;
    
endmodule