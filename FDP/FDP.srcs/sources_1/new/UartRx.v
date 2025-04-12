`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03/17/2025 01:26:16 PM
// Design Name: 
// Module Name: UartRx
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


module UartRx(
    input rx,
    input clk,
    input received,
    output reg [2:0] packetType,
    output reg [12:0] data,
    output reg valid = 1'b0
    );
    parameter BAUDRATE = 112500;
    parameter CLKFREQ = 100000000;
    localparam CYCLES_PER_BIT = CLKFREQ/BAUDRATE;
    reg [11:0] counter;
    reg [4:0] index;
    reg [17:0] packet;
    reg isReceiving = 1'b0;
    always @ (posedge clk) begin
    // CYCLES_PER_BIT/2 is used here to desync the sampling and the transmimssion
    // to ensure that signals are only sampled at the middle of transmission time
    // for stability
        if (!rx && !isReceiving && !received) begin
            isReceiving <= 1'b1;
            counter <= CYCLES_PER_BIT/2; 
            index <= 0;
        end
        if (isReceiving) begin
            if (counter < CYCLES_PER_BIT)
                counter <= counter + 1;
            else begin
                counter <= 12'b1;
                if (index < 18) begin
                    packet[index] <= rx;
                    index <= index + 1;
                    if (index == 17) begin
                        isReceiving <= 1'b0;
                        valid <= 1;
                        packetType <= packet[16:14];
                        data <= packet[13:1];
                    end
                end
            end
        end else if (valid && received) begin
            valid <= 0;
        end 
    end
    
endmodule
