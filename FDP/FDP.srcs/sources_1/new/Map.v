`timescale 1ns / 1ps

module Map (
    input clk,
    btnD,
    btnU,
    btnL,
    btnR,
    btnC,
    en,
    input JAin, //for UARTRx
    input [12:0] pixel_index,
    input [95:0] wall_tiles,
    output JAout, //for UARTTx
    output [3:0] led,
    input [95:0] breakable_tiles,
    input [95:0] powerup_tiles,
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

  // Random number generation
  reg [15:0] random_seed;

  // Clock Divider for game timing
  slow_clock c1 (
      .clk(clk),
      .period(1_000_000),
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
      .breakable_tiles(breakable_tiles),
      .powerup_tiles(powerup_tiles),
      .bomb_indices(bomb_indices),
      .bomb_en(bomb_en),
//      .en(en),
//      .user_direction(user_move),
//      .bot_direction(bot_move_wire),
      .oledColour(pixel_data)
  );

  // Collision detection for player
  is_collision is_wall_user (
      .cur_index(user_index),
      .wall_tiles(wall_tiles),
      .breakable_tiles(breakable_tiles),
      .powerup_tiles(powerup_tiles),
      .direction(user_move),
      .en(en),
      .new_index(new_user_index)
  );

  // Collision detection for enemy
  is_collision is_wall_bot (
      .cur_index(bot_index),
      .wall_tiles(wall_tiles),
      .breakable_tiles(breakable_tiles),
      .powerup_tiles(powerup_tiles),
      .direction(bot_move_wire),
      .en(en),
      .new_index(new_bot_index)
  );
  
  //UART TRANSMISSION
    reg tx_start;
    reg rx_receiving = 0;
    reg [15:0] data;
    wire busy;
    UartTx send (clk, tx_start, rx_receiving, data, JAout, busy);
    
  //UART RECEIVE
    wire valid, isReceiving;
    wire [2:0] packetType;
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
    reg readEn, writeEn; //enables read and write resp.
    reg [15:0] writeData; //data written into the buffer
    wire empty, full; //check if empty or full
    wire [15:0] readData; //data written from the buffer
    FIFOReg txBuffer (readEn, writeEn, clk, writeData, empty, full, readData);
   
    
    

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
      .powerup_tiles(powerup_tiles),
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
  assign dropBomb = (en && player_bombs_count != 0 && module_was_enabled && !first_enable_btnC_pressed) ? btnC_posedge : 0;
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
      if (dropBomb) begin
        bomb_indices[6:0] <= user_index; // Player bomb index
        bomb_en[0] <= 1;
        player_bombs_count <= player_bombs_count - 1;
      end

      // Handle enemy bomb placement
      if (dropBomb_enemy) begin
        bomb_indices[13:7] <= bot_index; // Enemy bomb index
        bomb_en[1] <= 1;
        enemy_bombs_count <= enemy_bombs_count - 1;
      end
      if (!empty && !busy) begin
        readEn <= 1'b1;
        data = readData;
      end else begin
        readEn <= 1'b0;
      end  
      
      // Reset bomb status when countdown reaches zero
      if (bomb_countdown == 0) bomb_en[0] <= 0;
      if (bomb_countdown_enemy == 0) bomb_en[1] <= 0;
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
    
    // Checks if new location will be updated and FIFO is full, then starts a write operation into FIFO
    if (user_index != new_user_index & !full) begin
        writeData <= {3'b000, 3'b000, new_user_index};
        writeEn <= 1'b1;
    end else writeEn <= 1'b0;
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