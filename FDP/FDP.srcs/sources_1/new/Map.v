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
    output [3:0] led,
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

  // Remove the bot_move register and directly use bot_move_wire
  wire [ 2:0] bot_move_wire;  // Already declared

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
  reg  [ 7:0] bombX;  // Bomb X position
  reg  [ 7:0] bombY;  // Bomb Y position
  reg  [ 7:0] bombX_enemy;  // Enemy bomb X position
  reg  [ 7:0] bombY_enemy;  // Enemy bomb Y position
  reg  [ 3:0] bomb_countdown;  // Countdown
  reg  [ 3:0] bomb_countdown_enemy;  // Enemy bomb countdown
  reg         dropBomb;
  wire        dropBomb_enemy;  // Enemy bomb drop signal

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
      .userX          (userXTile * TILE_SIZE),
      .userY          (userYTile * TILE_SIZE),
      .botX           (botXTile * TILE_SIZE),
      .botY           (botYTile * TILE_SIZE),
      .wall_tiles     (wall_tiles),
      .breakable_tiles(breakable_tiles),
      .bomb_en        (bomb_countdown != 0),
      .bombX          (bombX * TILE_SIZE),
      .bombY          (bombY * TILE_SIZE),
      .bomb_en_enemy  (bomb_countdown_enemy != 0),
      .bomb_enemy_x   (bombX_enemy * TILE_SIZE),
      .bomb_enemy_y   (bombY_enemy * TILE_SIZE),
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
      .direction(bot_move_wire),
      .en(en),
      .x_out(newYellowXTile),
      .y_out(newYellowYTile)
  );

  // Modify enemy_movement instantiation to use the wire
  enemy_movement enemy_move (
      .clk(clk),
      .en(en),
      .botX(botXTile),
      .botY(botYTile),
      .userX(userXTile),
      .userY(userYTile),
      .bomb1_x(bombX),
      .bomb1_y(bombY),
      .bomb2_x(bombX_enemy),
      .bomb2_y(bombY_enemy),
      .bomb1_en(bomb_countdown != 0),
      .bomb2_en(bomb_countdown_enemy != 0),
      .wall_tiles(wall_tiles),
      .breakable_tiles(breakable_tiles),
      .random_number(random_seed),
      .dropBomb(dropBomb_enemy),
      .led(led),
      .direction(bot_move_wire)
  );

  // Initialization block           
  initial begin
    userXTile      = GREEN_X_TILE;
    userYTile      = GREEN_Y_TILE;
    botXTile       = YELLOW_X_TILE;
    botYTile       = YELLOW_Y_TILE;
    user_move      = 0;
    bomb_countdown = 0;
    bomb_countdown_enemy = 0;
    dropBomb       = 0;
    random_seed    = 16'hACE1;  // Non-zero seed value
  end

  // Clock division and input processing
  always @(posedge clk) begin
    if (en) begin
      user_move <= en ? (btnU ? 1 : (btnR ? 2 : (btnD ? 3 : (btnL ? 4 : 0)))) : 0;
      dropBomb  <= en ? (bomb_countdown == 10) ? 0 : dropBomb | btnC : 0;
      // Set bomb at current position when center button pressed
      if (btnC) begin
        bombX <= userXTile;
        bombY <= userYTile;
      end
      // Set enemy bomb at current position when center button pressed
      if (dropBomb_enemy & bomb_countdown_enemy == 0) begin
        bombX_enemy <= botXTile;
        bombY_enemy <= botYTile;
      end
    end
  end

  always @(posedge clk1p0) begin
    random_seed <= {
      random_seed[14:0], random_seed[15] ^ random_seed[13] ^ random_seed[12] ^ random_seed[10]
    };

    bomb_countdown <= dropBomb ? 10 : bomb_countdown > 0 ? bomb_countdown - 1 : 0;
    bomb_countdown_enemy <= dropBomb_enemy ? 10 : bomb_countdown_enemy > 0 ? bomb_countdown_enemy - 1 : 0;

    userXTile <= en ? newGreenXTile : GREEN_X_TILE;
    userYTile <= en ? newGreenYTile : GREEN_Y_TILE;
    botXTile <= en ? newYellowXTile : YELLOW_X_TILE;
    botYTile <= en ? newYellowYTile : YELLOW_Y_TILE;
  end

endmodule
