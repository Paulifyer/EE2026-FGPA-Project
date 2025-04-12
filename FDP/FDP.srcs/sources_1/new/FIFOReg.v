`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/11/2025 10:16:02 PM
// Design Name: 
// Module Name: FIFOReg
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


module FIFOReg(
    input readEn, writeEn, clk,
    input [15:0] in,
    output empty, full,
    output reg [15:0] out
    );
    reg [15:0] buffer [7:0];
    reg [2:0] readPt = 3'b0;
    reg [2:0] writePt = 3'b0;
    reg [2:0] count = 3'b0;
    assign empty = (count == 0);
    assign full = (count == 8);
    
    always @ (posedge clk) begin
        //write operation
        if (writeEn && ~full) begin
            buffer[writePt] <= in;
            writePt <= (writePt == 7) ? 0 : (writePt + 1);
            count <= count + 1;
        end
        
        //read operation
        if (readEn && ~empty) begin
            out <= buffer[readPt];
            readPt <= (readPt == 7) ? 0 : (readPt + 1);
            count <= count - 1;
        end
    end
endmodule
