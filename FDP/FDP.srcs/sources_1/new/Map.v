`timescale 1ns / 1ps

module Map (
    input clk,
    keyDOWN,
    keyUP,
    keyLEFT,
    keyRIGHT,
    keyBOMB,
    input [3:0] state,
    input [1:0] sel,  //to pick sprites for player
    input JAin,  //for UARTRx
    input [12:0] pixel_index,
    input [95:0] wall_tiles,
    output JAout,  //for UARTTx
    input [95:0] breakable_tiles,
    input [95:0] powerup1_tiles,
    input [95:0] powerup2_tiles,
    input [95:0] powerup3_tiles,
    input [95:0] powerup4_tiles,
    input [95:0] powerup5_tiles,
    output [2:0] bombs,
    output [3:0] health,
    output [15:0] pixel_data
//    output death
);

  wire en;

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
  reg [6:0] user_index, bot_index;
  wire [6:0] new_user_index, new_bot_index;

  // Movement signals
  reg  [ 2:0] user_move;  // 1: up, 2: right, 3: down, 4: left
  wire [ 2:0] bot_move_wire;  // Bot movement wire from AI

  // Bomb management
  reg  [41:0] bomb_indices;
  reg  [ 5:0] bomb_en;
  reg [3:0] bomb_countdown, bomb_countdown_enemy;
  wire dropBomb, dropBomb_enemy;
  reg [1:0] player_bombs_count = 3, enemy_bombs_count = 3;

  // Button management
  wire keyBOMB_debounced;
  reg  keyBOMB_prev;
  reg  keyBOMB_enemy_prev;
  wire keyBOMB_posedge, keyBOMB_enemy_posedge;
  wire keyBOMB_enemy;

  // State tracking to prevent accidental bomb placement on first enable
  reg module_was_enabled = 0;
  reg first_enable_keyBOMB_pressed = 0;

  // Random number generation
  reg [15:0] random_seed;

    reg [95:0] after_powerup1_tiles;
    reg [95:0] after_powerup2_tiles;
    reg [95:0] after_powerup3_tiles;
    reg [95:0] after_powerup4_tiles;
    reg [95:0] after_powerup5_tiles;
    wire [20:0] bomb_tiles;
    wire [95:0] after_break_tiles, explosion_display;
    reg [2:0] bomb_limit = 1, bomb_range = 1;
    reg [13:0] bomb_time = 10000;
    reg [3:0] player_health = 4'b1111, bot_health = 4'b1111;
    wire [3:0] after_player_health, after_bot_health;
    wire [5:0] start_bomb;
    reg push_bomb_ability = 0;
    bomb boom (clk,keyBOMB_posedge,en,push_bomb_ability,wall_tiles,breakable_tiles,bomb_indices[41:21],user_index,bot_index,player_health,bot_health,bomb_limit,bomb_range,bomb_time,after_break_tiles,explosion_display,bomb_tiles,after_player_health,after_bot_health,start_bomb);

  // Clock Divider for game timing
  slow_clock c1 (
      .clk(clk),
      .period(100_000_000),
      .slow_clock(clk1p0)
  );

  // Button Debounce and Edge Detection
  switch_debounce debounce_keyBOMB (
      .clk(clk),
      .debound_count(50_000),
      .btn(keyBOMB),
      .btn_state(keyBOMB_debounced)
  );

  reg [1:0] state_counter = 0;
  reg en_delayed = 0;

  always @(posedge clk1p0) begin
    if (state == 2 & ~en_delayed) begin
      state_counter <= state_counter + 1;
      if (state_counter == 2) begin
        en_delayed <= 1;
        state_counter <= 0;
      end
    end else if (state == 0) begin
      en_delayed <= 0;
      state_counter <= 0;
    end else begin
      en_delayed <= en_delayed;  // Maintain the current state of en_delayed
    end
  end

  assign en = en_delayed & health[0] & (state == 2);

  // Button edge detection logic
  assign keyBOMB_posedge = keyBOMB_debounced & ~keyBOMB_prev;
  assign keyBOMB_enemy_posedge = keyBOMB_enemy & ~keyBOMB_enemy_prev;

  // Drawing logic for OLED display
  drawCordinate draw (
      .cordinateIndex(pixel_index),
      .user_index(user_index),
      .bot_index(bot_index),
      .wall_tiles(wall_tiles),
      .breakable_tiles(after_break_tiles),
      .explosion_display(explosion_display),
      .user_direction(user_move),
      .bot_direction(bot_move_wire),
      .powerup1_tiles(after_powerup1_tiles),
      .powerup2_tiles(after_powerup2_tiles),
      .powerup3_tiles(after_powerup3_tiles),
      .powerup4_tiles(after_powerup4_tiles),
      .powerup5_tiles(after_powerup5_tiles),
      .bomb_indices(bomb_indices),
      .bomb_en(bomb_en),
      .user_dead(player_health == 0 ? 1 : 0),
      .bot_dead(bot_health == 0 ? 1 : 0),
      .sel(sel),
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

  //UART TRANSMISSION
  reg tx_start;
  reg rx_receiving = 0;
  reg [15:0] data;
  wire busy;
  UartTx send (
      clk,
      tx_start,
      rx_receiving,
      data,
      JAout,
      busy
  );

  //UART RECEIVE
  wire valid, isReceiving;
  wire [ 2:0] packetType;
  wire [12:0] dataReceived;
  UartRx receive (
      .rx(JAin),
      .clk(clk),
      .packetType(packetType),
      .data(dataReceived),
      .valid(valid),
      .isReceiving(isReceiving)
  );

  //Transmission Buffer (FIFO)
  reg readEn, writeEn;  //enables read and write resp.
  reg [15:0] writeData;  //data written into the buffer
  wire empty, full;  //check if empty or full
  wire [15:0] readData;  //data written from the buffer
  FIFOReg txBuffer (
      readEn,
      writeEn,
      clk,
      writeData,
      empty,
      full,
      readData
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
      .breakable_tiles(breakable_tiles),
      .random_number(random_seed),
      .dropBomb(keyBOMB_enemy),
      .direction(bot_move_wire)
  );

  // Initialization
  initial begin
    user_index = GREEN_Y_TILE * GRID_WIDTH + GREEN_X_TILE;
    bot_index = YELLOW_Y_TILE * GRID_WIDTH + YELLOW_X_TILE;
    user_move = 0;
    bomb_countdown = 0;
    bomb_countdown_enemy = 0;
    bomb_en = 6'b000000;
    bomb_indices = {6{7'd127}};
    random_seed = 16'hACE1;
    module_was_enabled = 0;
    first_enable_keyBOMB_pressed = 0;
    keyBOMB_prev = 0;
    keyBOMB_enemy_prev = 0;
  end

  // Bomb placement logic
  assign dropBomb = (en & player_bombs_count != 0) ? keyBOMB_posedge : 0;
  assign dropBomb_enemy = (en & enemy_bombs_count != 0) ? keyBOMB_enemy_posedge : 0;

  // Input processing and bomb management (fast clock domain)
  always @(posedge clk) begin
    if (en) begin
      keyBOMB_prev <= keyBOMB_debounced;
      keyBOMB_enemy_prev <= keyBOMB_enemy;

      // Process directional input
      user_move <= keyUP ? 1 : (keyRIGHT ? 2 : (keyDOWN ? 3 : (keyLEFT ? 4 : 0)));

      // Track first enable state
      if (!module_was_enabled) begin
        module_was_enabled <= 1;
        first_enable_keyBOMB_pressed <= keyBOMB_debounced;
      end else if (first_enable_keyBOMB_pressed & !keyBOMB_debounced) begin
        // Reset the flag once the initial button press is released
        first_enable_keyBOMB_pressed <= 0;
      end
    
      // Handle player bomb placement
      //      if (dropBomb) begin
      //        bomb_indices[6:0] <= user_index;  // Player bomb index
      //        bomb_en[0] <= 1;
      //        player_bombs_count <= player_bombs_count - 1;
      //      end
      player_health <= after_player_health;
      bomb_en <= start_bomb;
      bomb_indices[20:0] <= bomb_tiles;

      // Handle enemy bomb placement
      if (dropBomb_enemy) begin
        // Set bomb at the correct index position based on enemy_bombs_count
        enemy_bombs_count = !start_bomb[3] + !start_bomb[4] + !start_bomb[5];
        case (enemy_bombs_count)
          3: bomb_indices[27:21] <= bot_index;
          2: bomb_indices[34:28] <= bot_index;
          1: bomb_indices[41:35] <= bot_index;
          default: /* Do nothing if no bombs left */;
        endcase
      end
      if (!empty & !busy) begin
        readEn <= 1'b1;
        data = readData;
      end else begin
        readEn <= 1'b0;
      end

      // Reset bomb status when countdown reaches zero
//      if (bomb_countdown == 0) bomb_en[0] <= 0;
//      if (bomb_countdown_enemy == 0) bomb_en[1] <= 0;
      
        if (after_powerup1_tiles[user_index] == 1) begin
            bomb_limit <= bomb_limit + (bomb_limit < 3);
            after_powerup1_tiles[user_index] <= 0;
        end
        else if (after_powerup2_tiles[user_index] == 1) begin
            push_bomb_ability <= 1;
            after_powerup2_tiles[user_index] <= 0;
        end
        else if (after_powerup3_tiles[user_index] == 1) begin
            player_health <= (player_health << 1) + 1'b1;
            after_powerup3_tiles[user_index] <= 0;
        end
        else if (after_powerup4_tiles[user_index] == 1) begin
            bomb_time <= bomb_time - 2000*(bomb_time > 1000);
            after_powerup4_tiles[user_index] <= 0;
        end
        else if (after_powerup5_tiles[user_index] == 1) begin
            bomb_range <= bomb_range + (bomb_range < 3);
            after_powerup5_tiles[user_index] <= 0;
        end
        if (after_powerup1_tiles[bot_index] == 1)
            after_powerup1_tiles[bot_index] <= 0;
        else if (after_powerup2_tiles[bot_index] == 1)
            after_powerup2_tiles[bot_index] <= 0;
        else if (after_powerup3_tiles[bot_index] == 1)
            after_powerup3_tiles[bot_index] <= 0;
        else if (after_powerup4_tiles[bot_index] == 1)
            after_powerup4_tiles[bot_index] <= 0;
        else if (after_powerup5_tiles[bot_index] == 1)
            after_powerup5_tiles[bot_index] <= 0;
    end else begin
      // Reset the enabled state when the module is disabled
      module_was_enabled <= 0;
      first_enable_keyBOMB_pressed <= 0;
      player_health <= 4'b1111;
      bomb_limit <= 1;
      bomb_range <= 1;
      bomb_time = 10000;
      push_bomb_ability = 0;
      after_powerup1_tiles <= powerup1_tiles;
      after_powerup2_tiles <= powerup2_tiles;
      after_powerup3_tiles <= powerup3_tiles;
      after_powerup4_tiles <= powerup4_tiles;
      after_powerup5_tiles <= powerup5_tiles;
    end
  end

  // Game state updates (slow clock domain)
  always @(posedge clk1p0) begin
    // Update bomb countdown timers
    random_seed <= {
      random_seed[14:0], random_seed[15] ^ random_seed[13] ^ random_seed[12] ^ random_seed[10]
    };

//    bomb_countdown <= bomb_en[0] ? bomb_countdown - 1 : 10;
//    bomb_countdown_enemy <= bomb_en[1] ? bomb_countdown_enemy - 1 : 10;

    // Checks if new location will be updated and FIFO is full, then starts a write operation into FIFO
    if (user_index != new_user_index & !full) begin
      writeData <= {3'b000, 3'b000, new_user_index};
      writeEn   <= 1'b1;
    end else writeEn <= 1'b0;
    // Update player positions using indices
    user_index <= en ? new_user_index : (GREEN_Y_TILE * GRID_WIDTH + GREEN_X_TILE);
    bot_index  <= en ? new_bot_index : (YELLOW_Y_TILE * GRID_WIDTH + YELLOW_X_TILE);
  end

  // Bomb count indicator for LEDs
  assign bombs = (((3'b111 << start_bomb[0]) << start_bomb[1]) << start_bomb[2]) << (3-bomb_limit);

//  assign death = player_health == 0 ? 1 : 0;
  assign health = player_health;

endmodule
