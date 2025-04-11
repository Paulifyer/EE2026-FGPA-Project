`timescale 1ns / 1ps

import Data_Item::*;

module bomb(
    input clk, keyBOMB, en, push_bomb_ability,
    input [95:0] wall_tiles, breakable_tiles,
    input [20:0] other_position_bomb, /* Other players bomb */
    input [6:0] player_index,
    input [2:0] player_health,
    bomb_limit, /* Number of bomb that can be place simultaneously */
    bomb_range, /* Bomb explosion radius in 12x8 grid measurement */
    input [13:0] bomb_time, /* Time taken for bomb to explode in milisecond */
    output reg [95:0] after_break_tiles,
    output [20:0] position_bomb_o,
    output reg [2:0] after_player_health,
    output reg [2:0] start_bomb = 0 /* To enable countdown for bomb */
    );
    
    wire clk_1ms, keyBOMB_state;;
    reg [6:0] position_bomb[2:0] = '{7'd127, 7'd127, 7'd127}; /* If bomb is not in used, it is place outside the map */
    reg [6:0] bomb_index, /* Single bomb index to calculate bomb explosion range in breakable tiles */
              bomb_offset, /* For pushing bomb */
              previous_player_index = player_index;
    wire [2:0] explode_bomb; /* Signal bomb exploded */
    
    /* Reg to store calculation */
    reg player_not_on_bomb;
    reg [5:0] bomb_index_x;
    reg [6:0] explode_up[2:0]; reg [6:0] explode_left[2:0]; reg [6:0] explode_right[2:0]; reg [6:0] explode_down[2:0];
    reg [6:0] bomb_indices[2:0]; reg [5:0] bomb_indices_x[2:0], bomb_indices_y[2:0];
    reg [2:0] bomb_wall_collision, bomb_screen_collision, bomb_constraint;
    
    slow_clock c0 (clk, 100000, clk_1ms);
    time_bomb_explosion t0 (clk_1ms, start_bomb[0], bomb_time, explode_bomb[0]);
    time_bomb_explosion t1 (clk_1ms, start_bomb[1], bomb_time, explode_bomb[1]);
    time_bomb_explosion t2 (clk_1ms, start_bomb[2], bomb_time, explode_bomb[2]);
    switch_debounce d1 (clk, 200, keyBOMB, keyBOMB_state); /* Prevent multiple placment of bomb*/
    
    assign position_bomb_o = {7'(position_bomb[2]),7'(position_bomb[1]),7'(position_bomb[0])};
    
    always @ (posedge clk) begin
        previous_player_index <= player_index; /* Store previous player index for pushing bomb */ 
        if (!en) begin
            after_break_tiles <= breakable_tiles;
            after_player_health <= player_health;
        end
        else if (keyBOMB_state) begin
            /* Place the bombs under the player index if:
               - It is not in used (ouside of the map)
               - Not occupy by other bombs
               - Within number of bomb placed (Maximum limited to 3 bombs simultaneously)
            */
            previous_player_index = player_index; /* Ensure bomb is place at player index */
            player_not_on_bomb = position_bomb[0] != player_index & position_bomb[1] != player_index & position_bomb[2] != player_index;
            if (position_bomb[0] == 127 && player_not_on_bomb) begin
                position_bomb[0] <= player_index;
                start_bomb[0] = 1;
            end
            else if (bomb_limit > 1 && position_bomb[1] == 127 && player_not_on_bomb) begin
                position_bomb[1] <= player_index;
                start_bomb[1] = 1;
            end
            else if (bomb_limit > 2 && position_bomb[2] == 127 && player_not_on_bomb) begin
                position_bomb[2] <= player_index;
                start_bomb[2] = 1;
            end
        end
        if (explode_bomb) begin
            /* Determine which bomb exploded and remove it */
            if (explode_bomb[0]) begin
                bomb_index <= position_bomb[0];
                position_bomb[0] <= 127;
                start_bomb[0] = 0;
            end
            else if (explode_bomb[1]) begin
                bomb_index <= position_bomb[1];
                position_bomb[1] <= 127;
                start_bomb[1] = 0;
            end
            else if (explode_bomb[2]) begin
                bomb_index <= position_bomb[2];
                position_bomb[2] <= 127;
                start_bomb[2] = 0;
            end
            else bomb_index <= 127;
            /* Bomb explosion destroy nearest breakable wall within it bomb range and reduce player health if hit */
            bomb_index_x = bomb_index/12;
            explode_up = '{7'(bomb_index-3*MAX_GRID_COLUMN),7'(bomb_index-2*MAX_GRID_COLUMN),7'(bomb_index-MAX_GRID_COLUMN)};
            explode_left = '{7'(bomb_index-3),7'(bomb_index-2),7'(bomb_index-1)};
            explode_right = '{7'(bomb_index+3),7'(bomb_index+2),7'(bomb_index+1)};
            explode_down = '{7'(bomb_index+3*MAX_GRID_COLUMN),7'(bomb_index+2*MAX_GRID_COLUMN),7'(bomb_index+MAX_GRID_COLUMN)};
            if (bomb_index == player_index)
                after_player_health <= after_player_health >> 1;
            /* Destroy in up direction */
            if (after_break_tiles[explode_up[0]] == 1 || wall_tiles[explode_up[0]] == 1)
                after_break_tiles[explode_up[0]] <= 0;
            else if (bomb_range > 1 && (after_break_tiles[explode_up[1]] == 1 || wall_tiles[explode_up[1]] == 1)) begin
                after_break_tiles[explode_up[1]] <= 0;
                if (explode_up[0] == player_index)
                    after_player_health <= after_player_health >> 1;
            end
            else if (bomb_range > 2 && (after_break_tiles[explode_up[2]] == 1 || wall_tiles[explode_up[2]] == 1)) begin
                after_break_tiles[explode_up[2]] <= 0;
                if (explode_up[0] == player_index || explode_up[1] == player_index)
                    after_player_health <= after_player_health >> 1;
            end
            else if (explode_up[0] == player_index || explode_up[1] == player_index || explode_up[2] == player_index)
                after_player_health <= after_player_health >> 1;
            /* Destroy in left direction */
            if ((explode_left[0])/12 == bomb_index_x && after_break_tiles[explode_left[0]] == 1 || wall_tiles[explode_left[0]] == 1)
                after_break_tiles[explode_left[0]] <= 0;
            else if (bomb_range > 1 && (explode_left[1])/12 == bomb_index_x && (after_break_tiles[explode_left[1]] == 1 || wall_tiles[explode_left[1]] == 1)) begin
                after_break_tiles[explode_left[1]] <= 0;
                if (explode_left[0] == player_index)
                    after_player_health <= after_player_health >> 1;
            end
            else if (bomb_range > 2 && (explode_left[2])/12 == bomb_index_x && (after_break_tiles[explode_left[2]] == 1 || wall_tiles[explode_left[2]] == 1)) begin
                after_break_tiles[explode_left[2]] <= 0;
                if (explode_left[0] == player_index || explode_left[1] == player_index)
                    after_player_health <= after_player_health >> 1;
            end
            else if (bomb_index_x == player_index/12 && (explode_left[0] == player_index || explode_left[1] == player_index || explode_left[2] == player_index))
                    after_player_health <= after_player_health >> 1;
            /* Destroy in right direction */
            if ((explode_right[0])/12 == bomb_index_x && after_break_tiles[explode_right[0]] == 1 || wall_tiles[explode_right[0]] == 1)
                after_break_tiles[explode_right[0]] <= 0;
            else if (bomb_range > 1 && (bomb_index+2)/12 == bomb_index_x && (after_break_tiles[bomb_index+2] == 1 || wall_tiles[bomb_index+2] == 1)) begin
                after_break_tiles[bomb_index+2] <= 0;
                if (explode_right[0] == player_index)
                    after_player_health <= after_player_health >> 1;
            end
            else if (bomb_range > 2 && (explode_right[2])/12 == bomb_index_x && (after_break_tiles[explode_right[2]] == 1 || wall_tiles[explode_right[2]] == 1)) begin
                after_break_tiles[explode_right[2]] <= 0;
                if (explode_right[0] == player_index || bomb_index+2 == player_index)
                    after_player_health <= after_player_health >> 1;
            end
            else if (bomb_index_x == player_index/12 && (explode_right[0] == player_index || explode_right[1] == player_index || explode_right[2] == player_index))
                after_player_health <= after_player_health >> 1;
            /* Destroy in down direction */
            if (after_break_tiles[explode_down[0]] == 1 || wall_tiles[explode_down[0]] == 1)
                after_break_tiles[explode_down[0]] <= 0;
            else if (bomb_range > 1 && (after_break_tiles[explode_down[1]] == 1 || wall_tiles[explode_down[1]] == 1)) begin
                after_break_tiles[explode_down[1]] <= 0;
                if (explode_down[0] == player_index)
                    after_player_health <= after_player_health >> 1;
            end
            else if (bomb_range > 2 && (after_break_tiles[explode_down[2]] == 1 || wall_tiles[explode_down[2]] == 1)) begin
                after_break_tiles[explode_down[2]] <= 0;
                if (explode_down[0] == player_index || explode_down[1] == player_index)
                    after_player_health <= after_player_health >> 1;
            end
            else if (explode_down[0] == player_index || explode_down[1] == player_index || explode_down[2] == player_index)
                after_player_health <= after_player_health >> 1;
        end
        /* Ability to push bomb forward */
        else if (push_bomb_ability && player_index != previous_player_index && (player_index == position_bomb[0] || player_index == position_bomb[1] || player_index == position_bomb[2])) begin
            /* Store player direction */
            bomb_offset = -(previous_player_index - player_index);
            /* Store calculations*/
            bomb_indices = '{7'(position_bomb[2] + bomb_offset),7'(position_bomb[1] + bomb_offset),7'(position_bomb[0] + bomb_offset)};
            bomb_indices_x = '{6'(bomb_indices[2]%12),6'(bomb_indices[1]%12),6'(bomb_indices[0]%12)};
            bomb_indices_y = '{6'(bomb_indices[2]/12),6'(bomb_indices[1]/12),6'(bomb_indices[0]/12)};
            bomb_wall_collision = {after_break_tiles[bomb_indices[2]] == 0 & wall_tiles[bomb_indices[2]] == 0, after_break_tiles[bomb_indices[1]] == 0 & wall_tiles[bomb_indices[1]] == 0, after_break_tiles[bomb_indices[0]] == 0 & wall_tiles[bomb_indices[0]] == 0};
            bomb_screen_collision = {(bomb_indices_x[2] == 0 | bomb_indices_x[2] == 11),(bomb_indices_x[1] == 0 | bomb_indices_x[1] == 11),(bomb_indices_x[0] == 0 | bomb_indices_x[0] == 11)};
            bomb_constraint = {bomb_indices[2] < 96 & !bomb_screen_collision[2] & bomb_wall_collision[2],bomb_indices[1] < 96 & !bomb_screen_collision[1] & bomb_wall_collision[1],bomb_indices[0] < 96 & !bomb_screen_collision[0] & bomb_wall_collision[0]};
            /* Change bomb location
               - Player push bomb
               - Bomb push bomb push bomb
            */
            if (player_index == position_bomb[0] && bomb_constraint[0]) begin
                if (bomb_indices[0] == position_bomb[1] && bomb_constraint[1]) begin
                    if (bomb_indices[1] == position_bomb[2]) begin
                        if (bomb_constraint[2])
                            position_bomb <= {7'(bomb_indices[2]),7'(bomb_indices[1]),7'(bomb_indices[0])};
                    end
                    else begin
                        position_bomb[0] <= bomb_indices[0];
                        position_bomb[1] <= bomb_indices[1];
                    end
                end
                else if (bomb_indices[0] == position_bomb[2] && bomb_constraint[2]) begin
                    if (bomb_indices[2] == position_bomb[1]) begin
                        if (bomb_constraint[1])
                            position_bomb <= {7'(bomb_indices[2]),7'(bomb_indices[1]),7'(bomb_indices[0])};
                    end
                    else begin
                        position_bomb[0] <= bomb_indices[0];
                        position_bomb[2] <= bomb_indices[2];
                    end
                end
                else
                    position_bomb[0] = bomb_indices[0];
            end
            else if (player_index == position_bomb[1] && bomb_constraint[1]) begin
                if (bomb_indices[1] == position_bomb[0] && bomb_constraint[0]) begin
                    if (bomb_indices[0] == position_bomb[2]) begin
                        if (bomb_constraint[2])
                            position_bomb <= {7'(bomb_indices[2]),7'(bomb_indices[1]),7'(bomb_indices[0])};
                    end
                    else begin
                            position_bomb[1] <= bomb_indices[1];
                            position_bomb[0] <= bomb_indices[0];
                    end
                end
                else if (bomb_indices[1] == position_bomb[2] && bomb_constraint[2]) begin
                    if (bomb_indices[2] == position_bomb[0]) begin
                        if (bomb_constraint[0])
                            position_bomb <= {7'(bomb_indices[2]),7'(bomb_indices[1]),7'(bomb_indices[0])};
                    end
                    else begin
                        position_bomb[1] <= bomb_indices[1];
                        position_bomb[2] <= bomb_indices[2];
                    end
                end
                else
                    position_bomb[1] <= bomb_indices[1];
            end
            else if (player_index == position_bomb[2] && bomb_constraint[2]) begin
                if (bomb_indices[2] == position_bomb[0] && bomb_constraint[0]) begin
                    if (bomb_indices[0] == position_bomb[1]) begin
                        if (bomb_constraint[1])
                            position_bomb <= {7'(bomb_indices[2]),7'(bomb_indices[1]),7'(bomb_indices[0])};
                    end
                    else begin
                        position_bomb[2] <= bomb_indices[2];
                        position_bomb[0] <= bomb_indices[0];
                    end
                end
                else if (bomb_indices[2] == position_bomb[1] && bomb_constraint[1]) begin
                    if (bomb_indices[1] == position_bomb[0]) begin
                        if (bomb_constraint[0])
                            position_bomb <= {7'(bomb_indices[2]),7'(bomb_indices[1]),7'(bomb_indices[0])};
                    end
                    else begin
                        position_bomb[2] <= bomb_indices[2];
                        position_bomb[1] <= bomb_indices[1];
                    end
                end
                else
                    position_bomb[2] <= bomb_indices[2];
            end
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