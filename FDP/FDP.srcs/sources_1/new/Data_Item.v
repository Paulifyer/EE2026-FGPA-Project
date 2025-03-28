`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 15.03.2025 21:50:50
// Design Name: 
// Module Name: Data_Item
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////



package Data_Item;
    parameter SCREEN_COLUMN = 96;
    parameter SCREEN_HEIGHT = 64;
    parameter MAX_GRID_COLUMN = SCREEN_COLUMN >> 3; // 12
    parameter MAX_GRID_ROW = SCREEN_HEIGHT >> 3; // 8
    parameter GRID_LENGTH = 8;
    parameter BLACK = 16'h0000, WHITE = 16'hFFFF, RED = 16'hF800, GREEN = 16'h07E0, BROWN = 16'h8A00;
    
//    parameter bomb_range = 1; /*bomb radius! not bomb diameter*/
//    parameter bomb_time = 2;
endpackage

