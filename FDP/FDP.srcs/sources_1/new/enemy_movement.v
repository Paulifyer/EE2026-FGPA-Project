`timescale 1ns / 1ps

module enemy_movement (
    input clk,
    input en,
    input [9:0] botX,
    input [9:0] botY,
    input [9:0] userX,
    input [9:0] userY,
    input [9:0] bomb1_x,
    input [9:0] bomb1_y,
    input bomb1_en,
    input [9:0] bomb2_x,
    input [9:0] bomb2_y,
    input bomb2_en,
    input [95:0] wall_tiles,
    input [95:0] breakable_tiles,
    input [15:0] random_number,
    output reg dropBomb,
    output [3:0] led,
    output reg [2:0] direction
);
  // Grid parameters
  parameter GRID_WIDTH = 12;
  parameter GRID_HEIGHT = 8;
  parameter CHASE_RANGE = 3;

  // State definitions
  parameter IDLE = 3'b000;
  parameter PATROLLING = 3'b001;
  parameter CHASING = 3'b010;
  parameter FLEEING = 3'b011;

  // Direction definitions
  parameter NO_MOVE = 3'd0;
  parameter UP = 3'd1;
  parameter RIGHT = 3'd2;
  parameter DOWN = 3'd3;
  parameter LEFT = 3'd4;

  // State registers
  reg [2:0] current_state = IDLE;
  reg [2:0] next_state = IDLE;
  reg [3:0] led_reg = 0;

  // Counters
  reg [5:0] patrol_counter = 0;
  reg [1:0] flee_counter = 0;  // Counter to track consecutive FLEEING states
  reg [1:0] patrol_after_flee_counter = 0;  // Counter to track PATROLLING cycles after FLEEING

  // Distance calculation
  wire [9:0] dx_player = (botX > userX) ? (botX - userX) : (userX - botX);
  wire [9:0] dy_player = (botY > userY) ? (botY - userY) : (userY - botY);
  wire [9:0] dist_to_player = dx_player + dy_player;

  // Bomb dropping logic
  reg [9:0] new_botX;
  reg [9:0] new_botY;

  // Bomb danger detection
  wire in_bomb1_danger, in_bomb2_danger, in_bomb_danger;
  assign in_bomb1_danger = bomb1_en ? (botX == bomb1_x || botY == bomb1_y) : 0;
  assign in_bomb2_danger = bomb2_en ? (botX == bomb2_x || botY == bomb2_y) : 0;
  assign in_bomb_danger  = in_bomb1_danger || in_bomb2_danger;

  // Collision detection function
  function is_collision;
    input [9:0] test_x, test_y;
    reg [5:0] tile_index;
    begin
      tile_index   = test_y * GRID_WIDTH + test_x;
      is_collision = (tile_index < 96) && (wall_tiles[tile_index] || breakable_tiles[tile_index]);
    end
  endfunction

  // Helper function to check if a position has a bomb
  function is_bomb_location;
    input [9:0] test_x, test_y;
    begin
      is_bomb_location = (bomb1_en && bomb1_x == test_x && bomb1_y == test_y) || 
                         (bomb2_en && bomb2_x == test_x && bomb2_y == test_y);
    end
  endfunction

  // State machine - next state logic
  always @(*) begin
    next_state = current_state;

    case (current_state)
      IDLE: begin
        if (dist_to_player <= CHASE_RANGE) next_state = CHASING;
        else if (random_number[15:14] == 2'b01) next_state = PATROLLING;
      end

      PATROLLING: begin
        if (patrol_after_flee_counter > 0) begin
          next_state = PATROLLING;  // Stay in PATROLLING for 3 cycles after FLEEING
        end else if (dist_to_player <= CHASE_RANGE) next_state = CHASING;
        else if (in_bomb_danger) next_state = FLEEING;
        else if (random_number[15:14] == 2'b00) next_state = IDLE;
      end

      CHASING: begin
        if (dist_to_player > CHASE_RANGE) next_state = PATROLLING;
        else if (in_bomb_danger) next_state = FLEEING;
      end

      FLEEING: begin
        if (!in_bomb_danger) next_state = PATROLLING;
      end
    endcase
  end

  // State machine - state and output logic
  always @(posedge clk) begin
    current_state <= next_state;
    led_reg <= current_state;

    // Handle fleeing counter logic
    if (current_state == FLEEING && next_state == PATROLLING) begin
      patrol_after_flee_counter <= 3;  // Initialize counter for 3 cycles
    end else if (patrol_after_flee_counter > 0) begin
      patrol_after_flee_counter <= patrol_after_flee_counter - 1;
    end

    // State-based movement behavior
    case (current_state)
      IDLE: direction <= NO_MOVE;

      PATROLLING: begin
        patrol_counter <= patrol_counter + 1;

        if (patrol_counter >= 30) begin
          patrol_counter <= 0;
          // Check that random direction doesn't lead to a bomb
          case (random_number[1:0] + 1)
            UP:
            if (!is_bomb_location(botX, botY - 1)) direction <= UP;
            else direction <= NO_MOVE;
            RIGHT:
            if (!is_bomb_location(botX + 1, botY)) direction <= RIGHT;
            else direction <= NO_MOVE;
            DOWN:
            if (!is_bomb_location(botX, botY + 1)) direction <= DOWN;
            else direction <= NO_MOVE;
            LEFT:
            if (!is_bomb_location(botX - 1, botY)) direction <= LEFT;
            else direction <= NO_MOVE;
          endcase
        end else if (is_collision(
                botX, botY - 1
            ) && direction == UP || is_bomb_location(
                botX, botY - 1
            ) && direction == UP)
          direction <= RIGHT;
        else if (is_collision(
                botX + 1, botY
            ) && direction == RIGHT || is_bomb_location(
                botX + 1, botY
            ) && direction == RIGHT)
          direction <= DOWN;
        else if (is_collision(
                botX, botY + 1
            ) && direction == DOWN || is_bomb_location(
                botX, botY + 1
            ) && direction == DOWN)
          direction <= LEFT;
        else if (is_collision(
                botX - 1, botY
            ) && direction == LEFT || is_bomb_location(
                botX - 1, botY
            ) && direction == LEFT)
          direction <= UP;
        else if ((direction == UP && (bomb1_en && bomb1_y == botY - 1 || bomb2_en && bomb2_y == botY - 1)) ||
                 (direction == RIGHT && (bomb1_en && bomb1_x == botX + 1 || bomb2_en && bomb2_x == botX + 1)) ||
                 (direction == DOWN && (bomb1_en && bomb1_y == botY + 1 || bomb2_en && bomb2_y == botY + 1)) ||
                 (direction == LEFT && (bomb1_en && bomb1_x == botX - 1 || bomb2_en && bomb2_x == botX - 1))) begin
          case (random_number[1:0])
            2'b00:
            if (!is_collision(
                    botX, botY - 1
                ) && !(bomb1_en && bomb1_y == botY - 1) && !(bomb2_en && bomb2_y == botY - 1))
              direction <= UP;
            2'b01:
            if (!is_collision(
                    botX + 1, botY
                ) && !(bomb1_en && bomb1_x == botX + 1) && !(bomb2_en && bomb2_x == botX + 1))
              direction <= RIGHT;
            2'b10:
            if (!is_collision(
                    botX, botY + 1
                ) && !(bomb1_en && bomb1_y == botY + 1) && !(bomb2_en && bomb2_y == botY + 1))
              direction <= DOWN;
            2'b11:
            if (!is_collision(
                    botX - 1, botY
                ) && !(bomb1_en && bomb1_x == botX - 1) && !(bomb2_en && bomb2_x == botX - 1))
              direction <= LEFT;
          endcase
        end
      end

      CHASING: begin
        if (dx_player == 0 && dy_player == 0) direction <= NO_MOVE;
        else if (dx_player > dy_player) begin
          if (botX < userX) begin
            if (!is_bomb_location(botX + 1, botY)) direction <= RIGHT;
            else if (botY < userY && !is_bomb_location(botX, botY + 1)) direction <= DOWN;
            else if (!is_bomb_location(botX, botY - 1)) direction <= UP;
            else direction <= NO_MOVE;
          end else begin
            if (!is_bomb_location(botX - 1, botY)) direction <= LEFT;
            else if (botY < userY && !is_bomb_location(botX, botY + 1)) direction <= DOWN;
            else if (!is_bomb_location(botX, botY - 1)) direction <= UP;
            else direction <= NO_MOVE;
          end
        end else begin
          if (botY < userY) begin
            if (!is_bomb_location(botX, botY + 1)) direction <= DOWN;
            else if (botX < userX && !is_bomb_location(botX + 1, botY)) direction <= RIGHT;
            else if (!is_bomb_location(botX - 1, botY)) direction <= LEFT;
            else direction <= NO_MOVE;
          end else begin
            if (!is_bomb_location(botX, botY - 1)) direction <= UP;
            else if (botX < userX && !is_bomb_location(botX + 1, botY)) direction <= RIGHT;
            else if (!is_bomb_location(botX - 1, botY)) direction <= LEFT;
            else direction <= NO_MOVE;
          end
        end
      end

      FLEEING: begin
        flee_counter <= flee_counter + 1;

        if (bomb1_en && bomb2_en && (bomb1_x == botX || bomb2_x == botX)) begin
          // When both bombs are active and on same X as bot, prioritize UP/DOWN movement
          if (!is_collision(botX, botY - 1) && !is_bomb_location(botX, botY - 1))
            direction <= UP;
          else if (!is_collision(botX, botY + 1) && !is_bomb_location(botX, botY + 1))
            direction <= DOWN;
          else if (!is_collision(botX - 1, botY) && !is_bomb_location(botX - 1, botY))
            direction <= LEFT;
          else if (!is_collision(botX + 1, botY) && !is_bomb_location(botX + 1, botY))
            direction <= RIGHT;
          else 
            direction <= NO_MOVE;
        end else if (bomb1_en && bomb2_en && (bomb1_y == botY || bomb2_y == botY)) begin
          // When both bombs are active and on same Y as bot, prioritize LEFT/RIGHT movement
          if (!is_collision(botX - 1, botY) && !is_bomb_location(botX - 1, botY))
            direction <= LEFT;
          else if (!is_collision(botX + 1, botY) && !is_bomb_location(botX + 1, botY))
            direction <= RIGHT;
          else if (!is_collision(botX, botY - 1) && !is_bomb_location(botX, botY - 1))
            direction <= UP;
          else if (!is_collision(botX, botY + 1) && !is_bomb_location(botX, botY + 1))
            direction <= DOWN;
          else
            direction <= NO_MOVE;
        end else if (bomb1_x == botX || bomb2_x == botX) begin
          // When one bomb is on same X as bot, prioritize UP/DOWN movement
          if (!is_collision(botX, botY - 1) && !is_bomb_location(botX, botY - 1))
            direction <= UP;
          else if (!is_collision(botX, botY + 1) && !is_bomb_location(botX, botY + 1))
            direction <= DOWN;
          else if (!is_collision(botX - 1, botY) && !is_bomb_location(botX - 1, botY))
            direction <= LEFT;
          else if (!is_collision(botX + 1, botY) && !is_bomb_location(botX + 1, botY))
            direction <= RIGHT;
          else
            direction <= NO_MOVE;
        end else if (bomb1_y == botY || bomb2_y == botY) begin
          // When one bomb is on same Y as bot, prioritize LEFT/RIGHT movement
          if (!is_collision(botX - 1, botY) && !is_bomb_location(botX - 1, botY))
            direction <= LEFT;
          else if (!is_collision(botX + 1, botY) && !is_bomb_location(botX + 1, botY))
            direction <= RIGHT;
          else if (!is_collision(botX, botY - 1) && !is_bomb_location(botX, botY - 1))
            direction <= UP;
          else if (!is_collision(botX, botY + 1) && !is_bomb_location(botX, botY + 1))
            direction <= DOWN;
          else
            direction <= NO_MOVE;
        end
      end
    endcase


    // Calculate new position based on current direction
    case (direction)
      UP: begin
        new_botX = botX;
        new_botY = botY - 1;
      end
      RIGHT: begin
        new_botX = botX + 1;
        new_botY = botY;
      end
      DOWN: begin
        new_botX = botX;
        new_botY = botY + 1;
      end
      LEFT: begin
        new_botX = botX - 1;
        new_botY = botY;
      end
      default: begin
        new_botX = botX;
        new_botY = botY;
      end
    endcase

    dropBomb <= ((new_botX == userX || new_botY == userY) && random_number[3:0] < 4'b0100) && 
                (!is_bomb_location(
        new_botX, new_botY
    ));
  end

  // LED output assignment
  assign led = led_reg;

endmodule
