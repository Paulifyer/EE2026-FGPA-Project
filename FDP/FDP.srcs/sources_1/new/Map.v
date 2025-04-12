`timescale 1ns / 1ps

module Map (
    input clk,
    keyDOWN,
    keyUP,
    keyLEFT,
    keyRIGHT,
    keyBOMB,
    input [2:0] sw,//USING FOR p1 and p2 logic, sw0 will be used to turn on multiplayer setting, sw1 will be for p1, sw2 for p2
    input [3:0] state,
    input [1:0] sel, //to pick sprites for player
    input JAin, //for UARTRx
    input [12:0] pixel_index,
    input [95:0] wall_tiles,
    output JAout, //for UARTTx
    output [6:0] led,
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
  reg  [2:0] user_move;  // 1: up, 2: right, 3: down, 4: left
  wire [2:0] bot_move_wire;  // Bot movement wire from AI

  // Bomb management
  reg [13:0] bomb_indices;
  reg [1:0] bomb_en;
  reg [3:0] bomb_countdown, bomb_countdown_enemy;
  wire dropBomb, dropBomb_enemy;
  reg [2:0] player_bombs_count = 4, enemy_bombs_count = 4;

  // Button management

  wire keyBOMB_debounced;
  reg keyBOMB_prev, keyBOMB_enemy_prev;
  wire keyBOMB_posedge, keyBOMB_enemy_posedge;
  wire keyBOMB_enemy;

  // State tracking to prevent accidental bomb placement on first enable
  reg module_was_enabled = 0;
  reg first_enable_keyBOMB_pressed = 0;

  // Random number generation
  reg [15:0] random_seed;
  
  wire en; //enable wire

  // Clock Divider for game timing
  slow_clock c1 (
      .clk(clk),
      .period(100_000_000),
      .slow_clock(clk1p0)
  );

  // Button Debounce and Edge Detection
  switch_debounce debounce_keyBOMB (
      .clk(clk),
      .debound_count(50000),
      .btn(keyBOMB),
      .btn_state(keyBOMB_debounced)
  );
  
  assign en = (state == 2);
 

  // Button edge detection logic
  assign keyBOMB_posedge = keyBOMB_debounced & ~keyBOMB_prev;
  assign keyBOMB_enemy_posedge = keyBOMB_enemy & ~keyBOMB_enemy_prev;

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
      .sel(sel),
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
    
    reg ready = 1'b0; //checks when acknowledge packet is received
    
    assign led[6] = ready; //LD[6] will light up when both boards are in ready state
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
    wire [15:0] readData; //data read from the buffer
    FIFOReg txBuffer (readEn, writeEn, clk, writeData, empty, full, readData);
   
    //Receive Buffer (FIFO)
    reg readEnR, writeEnR; //enables read and write resp.
    reg [15:0] writeDataR; //data written into the buffer
    wire emptyR, fullR; //check if empty or full
    wire [15:0] readDataR; //data read from the buffer
    FIFOReg rxBuffer (readEnR, writeEnR, clk, writeDataR, emptyR, fullR, readDataR);
    
    //Parses Packets from the FIFO
    wire pBusy;
    wire [2:0] pType;
    wire [12:0] pData;
    reg isRead;
    reg [15:0] inputPacket;
    reg readLatch = 0;
    PacketParser pp (inputPacket, clk, isRead, pBusy, pType, pData);

  // Enemy AI movement controller
  enemy_movement enemy_move (
      .clk(clk1p0),
      .en(en & ~sw[0]), //disables when sw[0] is HIGH
      .bot_index(bot_index),
      .user_index(user_index),
      .bomb_indices(bomb_indices),
      .bomb_en(bomb_en),
      .wall_tiles(wall_tiles),
      .breakable_tiles(breakable_tiles),
      .powerup_tiles(powerup_tiles),
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
    bomb_en = 2'b00;
    bomb_indices = 0;
    random_seed = 16'hACE1;
    module_was_enabled = 0;
    first_enable_keyBOMB_pressed = 0;
  end

  // Bomb placement logic
  assign dropBomb = (en && player_bombs_count != 0 && module_was_enabled && !first_enable_keyBOMB_pressed) ? keyBOMB_posedge : 0;
  assign dropBomb_enemy = (en && enemy_bombs_count != 0) ? keyBOMB_enemy_posedge : 0;

  // Input processing and bomb management (fast clock domain)
  always @(posedge clk) begin
    if (ready == 1'b0 && sw[0] && state == 3'b1) begin
        case (sw) 
            3'b011: begin //if master
                if (!busy) begin //starts sending a master packet
                    data <= {3'b111, 13'b1010101010101};
                    tx_start <= 1;
                end
                if (valid && ({packetType, dataReceived} == 16'b1110101010101010)) begin //waits for an acknowledgement packet
                    tx_start <= 0; //resets tx_start
                    ready <= 1; //sets Master to ready
                    
                end
            end 
            3'b101: begin //if slave
                if (valid && {packetType, dataReceived} == 16'b1111010101010101) begin //waits for a master packet
                    if (!busy) begin //sends an acknowledge packet
                        data <= 16'b1110101010101010;
                        tx_start <= 1;
                    end    
                end else begin
                    tx_start <= 0; //resets tx_start 
                    ready <= 1; //sets Slave to ready
                    user_index = YELLOW_Y_TILE * GRID_WIDTH + YELLOW_X_TILE;
                    bot_index = GREEN_Y_TILE * GRID_WIDTH + GREEN_X_TILE;
                end
            end
        endcase
    end
  
    //Write Operation for Receive FIFO for Uart data to be written
    if (!fullR & valid) begin
        writeEnR <= 1;
        writeDataR = {packetType, dataReceived};
    end else writeEnR <= 0;
    
    //Read Operation for Receive FIFO for data to be parsed
    // Returns: pType: the type of packet received
    //          pData: the data of the packet
    if (!emptyR & !pBusy) begin
        readEnR <= 1;
        inputPacket <= readData;
    end else readEnR <= 0;
    if (en) begin
      keyBOMB_prev <= keyBOMB_debounced;
      keyBOMB_enemy_prev <= keyBOMB_enemy;

      // Process directional input
      user_move <= keyUP ? 1 : (keyRIGHT ? 2 : (keyDOWN ? 3 : (keyLEFT ? 4 : 0)));

      // Track first enable state
      if (!module_was_enabled) begin
        module_was_enabled <= 1;
        first_enable_keyBOMB_pressed <= keyBOMB_debounced;
      end else if (first_enable_keyBOMB_pressed && !keyBOMB_debounced) begin
        // Reset the flag once the initial button press is released
        first_enable_keyBOMB_pressed <= 0;
      end
      
      // Handle player bomb placement
      if (dropBomb) begin
        bomb_indices[6:0] <= user_index; // Player bomb index
        bomb_en[0] <= 1;
        player_bombs_count <= player_bombs_count - 1;
        //Write Operation for Send FIFO buffer to transmit bomb data
        if (!full) begin
            writeEn <= 1'b1;
            writeData <= {3'b001, 6'b000000, user_index};
            tx_start <= 1;
        end else begin 
            writeEn <= 1'b0;
        end
      end

      // Handle enemy bomb placement
      if (dropBomb_enemy) begin
        bomb_indices[13:7] <= bot_index; // Enemy bomb index
        bomb_en[1] <= 1;
        enemy_bombs_count <= enemy_bombs_count - 1;
      end
      //Read Operation of the Send FIFO Buffer to dequeue the buffer and send data to the Tx to transmit
      if (!empty && !busy) begin
        readEn <= 1'b1;
        data <= readData;
        tx_start <= 1;
      end else begin
        readEn <= 1'b0;
        tx_start <= 0;
      end  
      
      // Reset bomb status when countdown reaches zero
      if (bomb_countdown == 0) bomb_en[0] <= 0;
      if (bomb_countdown_enemy == 0) bomb_en[1] <= 0;
    end else begin
      // Reset the enabled state when the module is disabled
      module_was_enabled <= 0;
      first_enable_keyBOMB_pressed <= 0;
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
        writeData <= {3'b000, 6'b000000, new_user_index};
        writeEn <= 1'b1;
    end else writeEn <= 1'b0;
    // Update player positions using indices
    user_index <= en ? new_user_index : (GREEN_Y_TILE * GRID_WIDTH + GREEN_X_TILE);
    if (ready && pType == 3'b000 && !pBusy && !readLatch) begin
        bot_index <= pData[6:0];
        isRead <= 1;
        readLatch <= 1;
    end else isRead <= 0;
    if (pBusy) readLatch <= 0;
    bot_index <= (en && !ready) ? new_bot_index : (YELLOW_Y_TILE * GRID_WIDTH + YELLOW_X_TILE);
  end

  // Bomb count indicator for LEDs
  assign bombs = player_bombs_count == 4 ? 4'b1111 : 
                 player_bombs_count == 3 ? 4'b0111 : 
                 player_bombs_count == 2 ? 4'b0011 : 
                 player_bombs_count == 1 ? 4'b0001 : 
                 4'b0000;

endmodule