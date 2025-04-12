`timescale 1ns / 1ps

module StateManager (
    input keySELECT,
    input clk,
    output reg [3:0] state = 4'b0
);
  localparam MENU = 4'b0000;
  localparam SPRITE = 4'b0001;
  localparam GAME = 4'b0010;
  localparam VICTORY = 4'b0011;
  localparam DEFEAT = 4'b0100;

  reg lastInput = 1'b0;
  always @(posedge clk) begin
    if (keySELECT & ~lastInput)
      if (state == MENU) state = SPRITE;
      else if (state == SPRITE) state = GAME;
    lastInput = keySELECT;
  end
endmodule
