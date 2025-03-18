`timescale 1ns / 1ps

//////////////////////////////////////////////////////////////////////////////////
//
//  FILL IN THE FOLLOWING INFORMATION:
//  STUDENT A NAME: 
//  STUDENT B NAME:
//  STUDENT C NAME: 
//  STUDENT D NAME:  
//
//////////////////////////////////////////////////////////////////////////////////


module Top_Student (
    input clk, btnC, btnU, btnL, btnR, btnD, JCIn,
    input [15:0] sw,
    output [15:0] led,
    output reg [7:0] seg,
    output reg [3:0] an,
    output [7:0] JB,
    output JCOut
    );
    wire clk_6p25MHz; wire halfSecClock;
    wire frame_begin, sending_pixels, sample_pixel; wire [12:0] pixel_index;
    wire [15:0] oled_data;
    wire state; wire busy; wire valid;
    wire [2:0] packetType; wire [12:0] data;
    SlowClock c1 (clk, 16, clk_6p25MHz);
    SlowClock c2 (clk, 200000000, halfSecClock);
    StateManager sM (btnC, clk, state);
    MainMenu menu (pixel_index, halfSecClock, state, oled_data);
    Oled_Display d1 (clk_6p25MHz, 0, frame_begin, sending_pixels, sample_pixel, pixel_index, oled_data, JB[0], JB[1], JB[3], JB[4], JB[5], JB[6], JB[7]);
    UartTx sendTest(clk, 1, 16'b1010101010101010, JCOut, busy);
    UartRx receiveTest(JCIn, clk, packetType, data, valid);
    assign led = {packetType ,data};
endmodule