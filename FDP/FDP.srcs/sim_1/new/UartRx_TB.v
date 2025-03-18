`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03/18/2025 01:55:45 PM
// Design Name: 
// Module Name: UartRx_TB
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


module UartRx_TB(
    );
    reg CLOCK = 1;
    always begin
        #5 CLOCK = ~CLOCK;
    end
    wire tx; wire busy; wire valid; wire isReceiving;
    reg tx_start;
    reg [15:0] packet;
    wire [2:0] packetType; wire [12:0] data;
    UartTx txTest (CLOCK, 1, isReceiving, packet, tx, busy);
    UartRx dut (tx, CLOCK, packetType, data, valid, isReceiving);
    initial begin
        packet = 16'b1010101010101010; tx_start = 1; #16000;
    end
endmodule
