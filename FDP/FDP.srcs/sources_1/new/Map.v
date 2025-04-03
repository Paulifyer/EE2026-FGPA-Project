`timescale 1ns / 1ps

module Map (
    input clk,
    btnD,
    btnU,
    btnL,
    btnR,
    btnC,
    en,
    input [12:0] pixel_index,
    input [95:0] wall_tiles,
    input [95:0] breakable_tiles,
    output [15:0] pixel_data
);
  // Grid parameters
  parameter TILE_SIZE = 8;  // Tile size in pixels
  parameter GRID_WIDTH = 12;  // 12 tiles horizontally
  parameter GRID_HEIGHT = 8;  // 8 tiles vertically
  parameter SCREEN_WIDTH = 96;  // Screen width in pixels
  parameter SCREEN_HEIGHT = 64;  // Screen height in pixels

  // Default location
  parameter GREEN_X_TILE = 0;
  parameter GREEN_Y_TILE = 4;
  parameter YELLOW_X_TILE = 3;
  parameter YELLOW_Y_TILE = 6;

  // movement control registers
  reg  [ 2:0] user_move;  // 1: up, 2: right, 3: down, 4: left
  reg  [ 2:0] bot_move;  // 1: up, 2: right, 3: down, 4: left

  // Position registers
  reg  [ 7:0] userXTile;
  reg  [ 7:0] userYTile;
  reg  [ 7:0] botXTile;
  reg  [ 7:0] botYTile;

  wire [ 7:0] newGreenXTile;
  wire [ 7:0] newGreenYTile;
  wire [ 7:0] newYellowXTile;
  wire [ 7:0] newYellowYTile;

  // Game state registers
  reg  [95:0] bomb_tiles;  // Bomb placement bitmap
  reg  [ 3:0] bomb_countdown;  // Countdown
  reg         dropBomb;

  // Add new registers for bot block and random generator
  reg  [15:0] random_seed;  // Random seed for bot user_movement

  wire        clk1p0;

  slow_clock c1 (
      .clk(clk),
      .period(1_0000_0000),
      .slow_clock(clk1p0)
  );

  // Module instantiation
  drawCordinate draw (
      .cordinateIndex (pixel_index),
      .userX         (userXTile * TILE_SIZE),
      .userY         (userYTile * TILE_SIZE),
      .botX        (botXTile * TILE_SIZE),
      .botY        (botYTile * TILE_SIZE),
      .wall_tiles     (wall_tiles),
      .breakable_tiles(breakable_tiles),
      .bomb_tiles     (bomb_tiles),
      .oledColour     (pixel_data)
  );

  is_collision is_wall_user (
      .x_cur(userXTile),
      .y_cur(userYTile),
      .wall_tiles(wall_tiles),
      .breakable_tiles(breakable_tiles),
      .direction(user_move),
      .en(en),
      .x_out(newGreenXTile),
      .y_out(newGreenYTile)
  );

  is_collision is_wall_bot (
      .x_cur(botXTile),
      .y_cur(botYTile),
      .wall_tiles(wall_tiles),
      .breakable_tiles(breakable_tiles),
      .direction(bot_move),
      .en(en),
      .x_out(newYellowXTile),
      .y_out(newYellowYTile)
  );

  // Initialization block           
  initial begin
    userXTile     = GREEN_X_TILE;
    userYTile     = GREEN_Y_TILE;
    botXTile    = YELLOW_X_TILE;
    botYTile    = YELLOW_Y_TILE;
    user_move     = 0;
    bot_move    = 0;
    bomb_tiles     = 0;
    bomb_countdown = 0;
    dropBomb       = 0;
    random_seed    = 16'hACE1;  // Non-zero seed value
  end

  // Clock division and input processing
  always @(posedge clk) begin
    user_move <= en ? (btnU ? 1 : (btnR ? 2 : (btnD ? 3 : (btnL ? 4 : 0)))) : 0;
    dropBomb   <= en ? (bomb_countdown == 10) ? 0 : dropBomb | btnC : 0;

    // Set bomb at current position when center button pressed
    if (en && btnC) begin
      bomb_tiles <= bomb_tiles | (1 << ((userYTile) * GRID_WIDTH + (userXTile)));
    end else if (bomb_countdown == 0) begin
      bomb_tiles <= 0;
    end else begin
      bomb_tiles <= bomb_tiles;
    end
  end

  always @(posedge clk1p0) begin
    random_seed <= {
      random_seed[14:0], random_seed[15] ^ random_seed[13] ^ random_seed[12] ^ random_seed[10]
    };
    userXTile <= en ? newGreenXTile : GREEN_X_TILE;
    userYTile <= en ? newGreenYTile : GREEN_Y_TILE;

    botXTile <= en ? newYellowXTile : YELLOW_X_TILE;
    botYTile <= en ? newYellowYTile : YELLOW_Y_TILE;

    bot_move <= en ? (random_seed[1:0] + 1) : 0;
    bomb_countdown <= dropBomb ? 10 : bomb_countdown > 0 ? bomb_countdown - 1 : 0;
  end

endmodule
