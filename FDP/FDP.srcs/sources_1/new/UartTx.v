`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03/17/2025 01:04:00 PM
// Design Name: 
// Module Name: UartTx
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



module UartTx(
    input clk,
    input tx_start,
    input rx_receiving,
    input [15:0] data,
    output reg tx = 1'b1, // PMOD PORT CONNECTED TO OTHER PMOD PORT
    output reg busy = 1'b0
    );
    parameter BAUDRATE = 112500;
    parameter CLKFREQ = 100000000;
    localparam CYCLES_PER_BIT = CLKFREQ/BAUDRATE; // Around 889
    reg [17:0] packet;
    reg [4:0] index = 5'b0;
    reg [11:0] counter;
    always @ (posedge clk) begin
        if (~busy && tx_start && ~rx_receiving) begin
            busy <= 1'b1;
            packet <= {1'b1, data, 1'b0};
            counter <= 12'b0;
            index <= 5'b0;
        end
        if (busy) begin
            if (counter < CYCLES_PER_BIT)
                counter <= counter + 1;
            else begin
                counter <= 12'b0;
                tx <= packet[0]; //LSB is being sent first
                packet <= packet >> 1;
                index <= index + 1;
                if (index == 17) 
                    busy <= 1'b0;
            end
        end
    end
endmodule
