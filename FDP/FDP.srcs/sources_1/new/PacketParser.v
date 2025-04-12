`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/12/2025 01:16:38 PM
// Design Name: 
// Module Name: PacketParser
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

//This module receives packets from the Receive Buffer and
//parses the packet into a type and data
//the type is used to determine where to send the data
module PacketParser(
    input [15:0] inputPacket,
    input clk,
    input isRead,
    output reg busy = 1'b0,
    output reg [2:0] packetType,
    output reg [12:0] data
    );
    
    reg parsedInternal = 0;
    
    always @ (posedge clk) begin
        if (!parsedInternal) begin
            parsedInternal <= 1'b1;
            packetType <= inputPacket[15:13];
            data <= inputPacket[12:0];
        end
        if (isRead & parsedInternal) begin
            parsedInternal <= 1'b0;
        end
        busy <= parsedInternal;
    end
endmodule
