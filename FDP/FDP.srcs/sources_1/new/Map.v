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
    output [3:0] bombs,
    output [15:0] pixel_data
);

  // Parameters
  parameter TILE_SIZE = 8;  // Tile size in pixels
  parameter GRID_WIDTH = 12;  // 12 tiles horizontally
  parameter GRID_HEIGHT = 8;  // 8 tiles vertically
  parameter SCREEN_WIDTH = 96;  // Screen width in pixels
  parameter SCREEN_HEIGHT = 64;  // Screen height in pixels

  // Starting positions
  parameter GREEN_X_TILE = 0;
  parameter GREEN_Y_TILE = 4;
  parameter YELLOW_X_TILE = 3;
  parameter YELLOW_Y_TILE = 6;

  // Clock signals
  wire clk1p0;  // 1Hz clock for movement updates

  // Player and enemy position registers as indices
  reg [6:0] user_index, bot_index;
  wire [6:0] new_user_index, new_bot_index;
  
  // Movement signals
  reg  [2:0] user_move;  // 1: up, 2: right, 3: down, 4: left
  wire [2:0] bot_move_wire;  // Bot movement wire from AI

  // Bomb management
  reg [13:0] bomb_indices; // 14 bits: [13:7] for enemy bomb, [6:0] for player bomb
  reg [1:0] bomb_en;
  reg [3:0] bomb_countdown, bomb_countdown_enemy;
  wire dropBomb, dropBomb_enemy;
  reg [2:0] player_bombs_count = 4, enemy_bombs_count = 4;
  
  // Button management
  wire btnC_debounced;
  reg btnC_prev, btnC_enemy_prev;
  wire btnC_posedge, btnC_enemy_posedge;
  wire btnC_enemy;

  // State tracking to prevent accidental bomb placement on first enable
  reg module_was_enabled = 0;
  reg first_enable_btnC_pressed = 0;

    wire [13:0] bomb_tiles;
    wire [95:0] after_break_tiles, explosion_display, pu_push;
    reg [2:0] bomb_limit = 1, bomb_range = 2;
    reg [13:0] bomb_time = 10000;
    reg [2:0] player_health = 3'b111;
    wire [2:0] new_player_health;
    wire [3:0] start_bomb;
    reg push_bomb_ability = 0;
    wire btnC_state;
    assign btnC_state = btnC_debounced & first_enable_btnC_pressed;
    bomb boom (clk,btnC_state,module_was_enabled,push_bomb_ability,wall_tiles,breakable_tiles,bomb_indices[13:7],user_index,player_health,bomb_limit,bomb_range,bomb_time,after_break_tiles,explosion_display,bomb_tiles,new_player_health,start_bomb);

  // Random number generation
  reg [15:0] random_seed;

  // Clock Divider for game timing
  slow_clock c1 (
      .clk(clk),
      .period(1_0000_0000),
      .slow_clock(clk1p0)
  );

  // Button Debounce and Edge Detection
  switch_debounce debounce_btnC (
      .clk(clk),
      .debound_count(50000),
      .btn(btnC),
      .btn_state(btnC_debounced)
  );

  // Button edge detection logic
  assign btnC_posedge = btnC_debounced & ~btnC_prev;
  assign btnC_enemy_posedge = btnC_enemy & ~btnC_enemy_prev;

  // Drawing logic for OLED display
  drawCordinate draw (
      .cordinateIndex(pixel_index),
      .user_index(user_index),
      .bot_index(bot_index),
      .wall_tiles(wall_tiles),
      .breakable_tiles(after_break_tiles),
      .explosion_display(explosion_display),
      .bomb_indices(bomb_indices),
      .bomb_en(bomb_en),
      .oledColour(pixel_data)
  );

  // Collision detection for player
  is_collision is_wall_user (
      .cur_index(user_index),
      .wall_tiles(wall_tiles),
      .breakable_tiles(after_break_tiles),
      .direction(user_move),
      .en(en),
      .new_index(new_user_index)
  );

  // Collision detection for enemy
  is_collision is_wall_bot (
      .cur_index(bot_index),
      .wall_tiles(wall_tiles),
      .breakable_tiles(after_break_tiles),
      .direction(bot_move_wire),
      .en(en),
      .new_index(new_bot_index)
  );

  // Enemy AI movement controller
  enemy_movement enemy_move (
      .clk(clk1p0),
      .en(en),
      .bot_index(bot_index),
      .user_index(user_index),
      .bomb_indices(bomb_indices),
      .bomb_en(bomb_en),
      .wall_tiles(wall_tiles),
      .breakable_tiles(after_break_tiles),
      .random_number(random_seed),
      .dropBomb(btnC_enemy),
      .direction(bot_move_wire)
  );

  // Initialization
  initial begin
    user_index = GREEN_Y_TILE * GRID_WIDTH + GREEN_X_TILE;
    bot_index = YELLOW_Y_TILE * GRID_WIDTH + YELLOW_X_TILE;
    user_move = 0;
    bomb_countdown = 0;
    bomb_countdown_enemy = 0;
    bomb_en = 2'b00;
    bomb_indices = 0;
    random_seed = 16'hACE1;
    module_was_enabled = 0;
    first_enable_btnC_pressed = 0;
  end

  // Bomb placement logic
//  assign dropBomb = (en && player_bombs_count != 0 && module_was_enabled && !first_enable_btnC_pressed) ? btnC_posedge : 0;
  assign dropBomb_enemy = (en && enemy_bombs_count != 0) ? btnC_enemy_posedge : 0;

  // Input processing and bomb management (fast clock domain)
  always @(posedge clk) begin
    if (en) begin
      btnC_prev <= btnC_debounced;
      btnC_enemy_prev <= btnC_enemy;

      // Process directional input
      user_move <= btnU ? 1 : (btnR ? 2 : (btnD ? 3 : (btnL ? 4 : 0)));

      // Track first enable state
      if (!module_was_enabled) begin
        module_was_enabled <= 1;
        first_enable_btnC_pressed <= btnC_debounced;
      end else if (first_enable_btnC_pressed && !btnC_debounced) begin
        // Reset the flag once the initial button press is released
        first_enable_btnC_pressed <= 0;
      end

      // Handle player bomb placement
//      if (dropBomb) begin
//        bomb_indices[6:0] <= user_index; // Player bomb index
//        bomb_en[0] <= 1;
//        player_bombs_count <= player_bombs_count - 1;
//      end
      bomb_indices[6:0] <= bomb_tiles[6:0];
      bomb_en[0] <= start_bomb[0];

      // Handle enemy bomb placement
      if (dropBomb_enemy) begin
        bomb_indices[13:7] <= bot_index; // Enemy bomb index
        bomb_en[1] <= 1;
        enemy_bombs_count <= enemy_bombs_count - 1;
      end

      // Reset bomb status when countdown reaches zero
      if (bomb_countdown == 0) bomb_en[0] <= 0;
      if (bomb_countdown_enemy == 0) bomb_en[1] <= 0;
      
      // Player get push powerup
      if (pu_push[user_index] == 1'b1)
        push_bomb_ability = 1;
        
    end else begin
      // Reset the enabled state when the module is disabled
      module_was_enabled <= 0;
      first_enable_btnC_pressed <= 0;
    end
  end

  // Game state updates (slow clock domain)
  always @(posedge clk1p0) begin
    // Update bomb countdown timers
    random_seed <= {
      random_seed[14:0], random_seed[15] ^ random_seed[13] ^ random_seed[12] ^ random_seed[10]
    };

    bomb_countdown <= bomb_en[0] ? bomb_countdown - 1 : 10;
    bomb_countdown_enemy <= bomb_en[1] ? bomb_countdown_enemy - 1 : 10;

    // Update player positions using indices
    user_index <= en ? new_user_index : (GREEN_Y_TILE * GRID_WIDTH + GREEN_X_TILE);
    bot_index <= en ? new_bot_index : (YELLOW_Y_TILE * GRID_WIDTH + YELLOW_X_TILE);
  end

  // Bomb count indicator for LEDs
  assign bombs = player_bombs_count == 4 ? 4'b1111 : 
                 player_bombs_count == 3 ? 4'b0111 : 
                 player_bombs_count == 2 ? 4'b0011 : 
                 player_bombs_count == 1 ? 4'b0001 : 
                 4'b0000;

endmodule
