`timescale 1ns / 1ps

import Data_Item::*;

module bomb(
    input clk, btnC, en, push_bomb_ability,
    input [95:0] wall_tiles, breakable_tiles,
    input [6:0] player_index,
    input [2:0] player_health,
    bomb_limit, /* Number of bomb that can be place simultaneously */
    bomb_range, /* Bomb explosion radius in 12x8 grid measurement */
    input [13:0] bomb_time, /* Time taken for bomb to explode in milisecond */
    output reg [95:0] after_break_tiles,
    output reg [20:0] position_bomb = {7'd127,7'd127,7'd127}, /* If bomb is not in used, it is place outside the map */
    output reg [2:0] after_player_health
    );
    
    wire clk_1ms, btnC_state;
    reg [2:0] start_bomb = 0, /* To enable countdown for bomb */
              direction;
    reg [6:0] bomb_index, /* Single bomb index to calculate bomb explosion range in breakable tiles */
              bomb_offset, /* For pushing bomb */
              previous_player_index = player_index;
    wire [2:0] explode_bomb; /* Signal bomb exploded */
//    wire [11:0] damage_up, damage_left, damage_right, damage_down; /* To check bomb surrounding */
//    reg [7:0] collision_x, collision_y;
    
    slow_clock c0 (clk, 100000, clk_1ms);
    time_bomb_explosion t0 (clk_1ms, start_bomb[0], bomb_time, explode_bomb[0]);
    time_bomb_explosion t1 (clk_1ms, start_bomb[1], bomb_time, explode_bomb[1]);
    time_bomb_explosion t2 (clk_1ms, start_bomb[2], bomb_time, explode_bomb[2]);
    switch_debounce d1 (clk, 200, btnC, btnC_state); /* Prevent multiple placment of bomb*/
//    is_collision l1 (bomb_index%MAX_GRID_COLUMN,bomb_index/MAX_GRID_COLUMN,wall_tiles,after_break_tiles,direction,en,collision_x,collision_y);
    
//    assign damage_up = {4'(bomb_index-MAX_GRID_COLUMN),4'(bomb_index-2*MAX_GRID_COLUMN),4'(bomb_index-3*MAX_GRID_COLUMN)};
//    assign damage_left = {4'(bomb_index-1),4'(bomb_index-2),4'(bomb_index-3)};
//    assign damage_right = {4'(bomb_index+1),4'(bomb_index+2),4'(bomb_index+3)};
//    assign damage_down = {4'(bomb_index+MAX_GRID_COLUMN),4'(bomb_index+2*MAX_GRID_COLUMN),4'(bomb_index+3*MAX_GRID_COLUMN)};

    always @ (posedge clk) begin
        previous_player_index <= player_index; /* Store previous player index for pushing bomb */ 
        if (!en) begin
            after_break_tiles = breakable_tiles;
            after_player_health = player_health;
        end
        else if (btnC_state) begin
            /* Place the bombs under the player index if:
               - It is not in used (ouside of the map)
               - Not occupy by other bombs
               - Within number of bomb placed (Maximum limited to 3 bombs simultaneously)
            */
            previous_player_index = player_index; /* Ensure bomb is at player index*/
            if (position_bomb[6:0] == 127 && position_bomb[13:7] != player_index && position_bomb[20:14] != player_index) begin
                position_bomb[6:0] = player_index;
                start_bomb[0] = 1;
            end
            else if (bomb_limit > 1 && position_bomb[13:7] == 127 && position_bomb[6:0] != player_index && position_bomb[20:14] != player_index) begin
                position_bomb[13:7] = player_index;
                start_bomb[1] = 1;
            end
            else if (bomb_limit > 2 && position_bomb[20:14] == 127 && position_bomb[6:0] != player_index && position_bomb[13:7] != player_index) begin
                position_bomb[20:14] = player_index;
                start_bomb[2] = 1;
            end
        end
        if (explode_bomb) begin
            /* Determine which bomb exploded and remove it */
            if (explode_bomb[0]) begin
                bomb_index = position_bomb[6:0];
                position_bomb[6:0] = 127;
                start_bomb[0] = 0;
            end
            else if (explode_bomb[1]) begin
                bomb_index = position_bomb[13:7];
                position_bomb[13:7] = 127;
                start_bomb[1] = 0;
            end
            else if (explode_bomb[2]) begin
                bomb_index = position_bomb[20:14];
                position_bomb[20:14] = 127;
                start_bomb[2] = 0;
            end
            else bomb_index = 127;
            /* Bomb explosion destroy nearest breakable wall within it bomb range and reduce player health if hit */
            /* Destroy in up direction */
            if (after_break_tiles[bomb_index-MAX_GRID_COLUMN] == 1 || wall_tiles[bomb_index-MAX_GRID_COLUMN] == 1)
                after_break_tiles[bomb_index-MAX_GRID_COLUMN] = 0;
            else if (bomb_range > 1 && (after_break_tiles[bomb_index-2*MAX_GRID_COLUMN] == 1 || wall_tiles[bomb_index-2*MAX_GRID_COLUMN] == 1)) begin
                after_break_tiles[bomb_index-2*MAX_GRID_COLUMN] = 0;
                if (bomb_index-MAX_GRID_COLUMN == player_index)
                    after_player_health = after_player_health >> 1;
            end
            else if (bomb_range > 2 && (after_break_tiles[bomb_index-3*MAX_GRID_COLUMN] == 1 || wall_tiles[bomb_index-3*MAX_GRID_COLUMN] == 1)) begin
                after_break_tiles[bomb_index-3*MAX_GRID_COLUMN] = 0;
                if (bomb_index-MAX_GRID_COLUMN == player_index || bomb_index-2*MAX_GRID_COLUMN == player_index)
                    after_player_health = after_player_health >> 1;
            end
            else if (bomb_index-MAX_GRID_COLUMN == player_index || bomb_index-2*MAX_GRID_COLUMN == player_index || bomb_index-3*MAX_GRID_COLUMN == player_index)
                after_player_health = after_player_health >> 1;
            /* Destroy in left direction */
            if (after_break_tiles[bomb_index-1] == 1 || wall_tiles[bomb_index-1] == 1)
                after_break_tiles[bomb_index-1] = 0;
            else if (bomb_range > 1 && (after_break_tiles[bomb_index-2] == 1 || wall_tiles[bomb_index-2] == 1)) begin
                after_break_tiles[bomb_index-2] = 0;
                if (bomb_index-1 == player_index)
                    after_player_health = after_player_health >> 1;
            end
            else if (bomb_range > 2 && (after_break_tiles[bomb_index-3] == 1 || wall_tiles[bomb_index-3] == 1)) begin
                after_break_tiles[bomb_index-3] = 0;
                if (bomb_index-1 == player_index || bomb_index-2 == player_index)
                    after_player_health = after_player_health >> 1;
            end
            else if (bomb_index-1 == player_index || bomb_index-2 == player_index || bomb_index-3 == player_index)
                    after_player_health = after_player_health >> 1;
            /* Destroy in right direction */
            if (after_break_tiles[bomb_index+1] == 1 || wall_tiles[bomb_index+1] == 1)
                after_break_tiles[bomb_index+1] = 0;
            else if (bomb_range > 1 && (after_break_tiles[bomb_index+2] == 1 || wall_tiles[bomb_index+2] == 1)) begin
                after_break_tiles[bomb_index+2] = 0;
                if (bomb_index+1 == player_index)
                    after_player_health = after_player_health >> 1;
            end
            else if (bomb_range > 2 && (after_break_tiles[bomb_index+3] == 1 || wall_tiles[bomb_index+3] == 1)) begin
                after_break_tiles[bomb_index+3] = 0;
                if (bomb_index+1 == player_index || bomb_index+2 == player_index)
                    after_player_health = after_player_health >> 1;
            end
            else if (bomb_index+1 == player_index || bomb_index+2 == player_index || bomb_index+3 == player_index)
                after_player_health = after_player_health >> 1;
            /* Destroy in down direction */
            if (after_break_tiles[bomb_index+MAX_GRID_COLUMN] == 1 || wall_tiles[bomb_index+MAX_GRID_COLUMN] == 1)
                after_break_tiles[bomb_index+MAX_GRID_COLUMN] = 0;
            else if (bomb_range > 1 && (after_break_tiles[bomb_index+2*MAX_GRID_COLUMN] == 1 || wall_tiles[bomb_index+2*MAX_GRID_COLUMN] == 1)) begin
                after_break_tiles[bomb_index+2*MAX_GRID_COLUMN] = 0;
                if (bomb_index+MAX_GRID_COLUMN == player_index)
                    after_player_health = after_player_health >> 1;
            end
            else if (bomb_range > 2 && (after_break_tiles[bomb_index+3*MAX_GRID_COLUMN] == 1 || wall_tiles[bomb_index+3*MAX_GRID_COLUMN] == 1)) begin
                after_break_tiles[bomb_index+3*MAX_GRID_COLUMN] = 0;
                if (bomb_index+MAX_GRID_COLUMN == player_index || bomb_index+2*MAX_GRID_COLUMN == player_index)
                    after_player_health = after_player_health >> 1;
            end
            else if (bomb_index+MAX_GRID_COLUMN == player_index || bomb_index+2*MAX_GRID_COLUMN == player_index || bomb_index+3*MAX_GRID_COLUMN == player_index)
                after_player_health = after_player_health >> 1;
        end
        /* Ability to push bomb forward */
        else if (push_bomb_ability && player_index != previous_player_index && (player_index == position_bomb[6:0] || player_index == position_bomb[13:7] || player_index == position_bomb[20:14])) begin
            /* Store player direction move up */
            if (previous_player_index - player_index == 12)
                bomb_offset = -12;
            /* Store player direction move down */
            else if (previous_player_index - player_index == -12)
                bomb_offset = 12;
            /* Store player direction move left */
            else if (previous_player_index - player_index == 1)
                bomb_offset = - 1;
            /* Store player direction move right */
            else if (previous_player_index - player_index == -1)
                bomb_offset = 1;
            /* Change bomb location
               - Player push bomb
               - Bomb push bomb
            */
            if (player_index == position_bomb[6:0]) begin
                position_bomb[6:0] = position_bomb[6:0] + bomb_offset;
                if (position_bomb[6:0] == position_bomb[13:7])
                    position_bomb[13:7] = position_bomb[13:7] + bomb_offset;
                else if (position_bomb[6:0] == position_bomb[20:14])
                    position_bomb[20:14] = position_bomb[20:14] + bomb_offset;
            end
            else if (player_index == position_bomb[13:7]) begin
                position_bomb[13:7] = position_bomb[13:7] + bomb_offset;
                if (position_bomb[13:7] == position_bomb[6:0])
                    position_bomb[6:0] = position_bomb[6:0] + bomb_offset;
                else if (position_bomb[13:7] == position_bomb[20:14])
                    position_bomb[20:14] = position_bomb[20:14] + bomb_offset;
            end
            else if (player_index == position_bomb[20:14]) begin
                position_bomb[20:14] = position_bomb[20:14] + bomb_offset;
                if (position_bomb[20:14] == position_bomb[6:0])
                    position_bomb[6:0] = position_bomb[6:0] + bomb_offset;
                else if (position_bomb[20:14] == position_bomb[13:7])
                    position_bomb[13:7] = position_bomb[13:7] + bomb_offset;
            end
            else bomb_index = 127;
        end
    end
endmodule

module time_bomb_explosion(input clk, start, input [13:0] bomb_time, output reg bomb_exploded = 0);
        /* Countdown time for bomb explosion */
        reg [13:0] count = 0;
        always @(posedge clk) begin
            bomb_exploded <= (count == bomb_time);
            if (!start) count <= 0;
            else count <= count + (count < bomb_time);
        end
    endmodule