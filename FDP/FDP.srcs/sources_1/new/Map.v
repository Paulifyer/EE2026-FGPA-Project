`timescale 1ns / 1ps

module Map (
    input clk,
    // Movement inputs now come directly from Top_Student
    input [2:0] user_move, // 1: up, 2: right, 3: down, 4: left
    input [2:0] bot_move,  // Bot movement direction from Top_Student
    input dropBomb,        // Player bomb drop signal
    input dropBomb_enemy,  // Enemy bomb drop signal
    input en,
    input [12:0] pixel_index,
    input [95:0] wall_tiles,
    output [3:0] led,
    input [95:0] breakable_tiles,
    output [3:0] bombs,
    output [15:0] pixel_data,
    // Expose indices for movement calculation in Top_Student
    output [6:0] user_index,
    output [6:0] bot_index,
    output [6:0] new_user_index,
    output [6:0] new_bot_index,
    output [13:0] bomb_indices,
    output [1:0] bomb_en
);

  // Parameters
  parameter TILE_SIZE = 8;  // Tile size in pixels
  parameter GRID_WIDTH = 12;  // 12 tiles horizontally
  parameter GRID_HEIGHT = 8;  // 8 tiles vertically
  parameter SCREEN_WIDTH = 96;  // Screen width in pixels
  parameter SCREEN_HEIGHT = 64;  // Screen height in pixels

  // Starting positions
  parameter GREEN_X_TILE = 1;
  parameter GREEN_Y_TILE = 1;
  parameter YELLOW_X_TILE = 10;
  parameter YELLOW_Y_TILE = 6;

  // Clock signals
  wire clk1p0;  // 1Hz clock for movement updates

  // Player and enemy position registers as indices
  reg [6:0] user_index_reg, bot_index_reg;
  
  // Bomb management
  reg [13:0] bomb_indices_reg; // 14 bits: [13:7] for enemy bomb, [6:0] for player bomb
  reg [1:0] bomb_en_reg;
  reg [3:0] bomb_countdown, bomb_countdown_enemy;
  reg [2:0] player_bombs_count = 4, enemy_bombs_count = 4;

  // Assign output signals
  assign user_index = user_index_reg;
  assign bot_index = bot_index_reg;
  assign bomb_indices = bomb_indices_reg;
  assign bomb_en = bomb_en_reg;

  // Clock Divider for game timing
  slow_clock c1 (
      .clk(clk),
      .period(1_0000_0000),
      .slow_clock(clk1p0)
  );

  // Drawing logic for OLED display
  drawCordinate draw (
      .cordinateIndex(pixel_index),
      .user_index(user_index_reg),
      .bot_index(bot_index_reg),
      .wall_tiles(wall_tiles),
      .breakable_tiles(breakable_tiles),
      .bomb_indices(bomb_indices_reg),
      .bomb_en(bomb_en_reg),
      .oledColour(pixel_data)
  );

  // Collision detection for player
  is_collision is_wall_user (
      .cur_index(user_index_reg),
      .wall_tiles(wall_tiles),
      .breakable_tiles(breakable_tiles),
      .direction(user_move),
      .en(en),
      .new_index(new_user_index)
  );

  // Collision detection for enemy
  is_collision is_wall_bot (
      .cur_index(bot_index_reg),
      .wall_tiles(wall_tiles),
      .breakable_tiles(breakable_tiles),
      .direction(bot_move),
      .en(en),
      .new_index(new_bot_index)
  );

  // Initialization
  initial begin
    user_index_reg = GREEN_Y_TILE * GRID_WIDTH + GREEN_X_TILE;
    bot_index_reg = YELLOW_Y_TILE * GRID_WIDTH + YELLOW_X_TILE;
    bomb_countdown = 0;
    bomb_countdown_enemy = 0;
    bomb_en_reg = 2'b00;
    bomb_indices_reg = 0;
  end

  // Input processing and bomb management (fast clock domain)
  always @(posedge clk) begin
    if (en) begin
      // Handle player bomb placement
      if (dropBomb) begin
        bomb_indices_reg[6:0] <= user_index_reg; // Player bomb index
        bomb_en_reg[0] <= 1;
        player_bombs_count <= player_bombs_count - 1;
      end

      // Handle enemy bomb placement
      if (dropBomb_enemy) begin
        bomb_indices_reg[13:7] <= bot_index_reg; // Enemy bomb index
        bomb_en_reg[1] <= 1;
        enemy_bombs_count <= enemy_bombs_count - 1;
      end

      // Reset bomb status when countdown reaches zero
      if (bomb_countdown == 0) bomb_en_reg[0] <= 0;
      if (bomb_countdown_enemy == 0) bomb_en_reg[1] <= 0;
    end
  end

  // Game state updates (slow clock domain)
  always @(posedge clk1p0) begin
    // Update bomb countdown timers
    bomb_countdown <= bomb_en_reg[0] ? bomb_countdown - 1 : 10;
    bomb_countdown_enemy <= bomb_en_reg[1] ? bomb_countdown_enemy - 1 : 10;

    // Update player positions using indices
    user_index_reg <= en ? new_user_index : (GREEN_Y_TILE * GRID_WIDTH + GREEN_X_TILE);
    bot_index_reg <= en ? new_bot_index : (YELLOW_Y_TILE * GRID_WIDTH + YELLOW_X_TILE);
  end

  // Bomb count indicator for LEDs
  assign bombs = player_bombs_count == 4 ? 4'b1111 : 
                 player_bombs_count == 3 ? 4'b0111 : 
                 player_bombs_count == 2 ? 4'b0011 : 
                 player_bombs_count == 1 ? 4'b0001 : 
                 4'b0000;

endmodule
