`timescale 1ns / 1ps

import Data_Item::*;

module bomb(
    input clk, btnC_state, en, push_bomb_ability,
    input [95:0] wall_tiles, breakable_tiles,
    input [7:0] other_position_bomb_i, /* Other players bomb */
    input [6:0] player_index,
    input [2:0] player_health,
    bomb_limit, /* Number of bomb that can be place simultaneously */
    bomb_range, /* Bomb explosion radius in 12x8 grid measurement */
    input [13:0] bomb_time, /* Time taken for bomb to explode in milisecond */
    output reg [95:0] after_break_tiles,
    output reg [95:0] explosion_display,
    output [6:0][1:0] position_bomb_o,
    output reg [2:0] after_player_health,
    output reg [3:0] start_bomb = 0 /* To enable countdown for bomb */
    );
    
    wire clk_1ms;//, btnC_state;
    reg [6:0] position_bomb[2:0] = '{7'd127, 7'd127, 7'd127}; /* If bomb is not in used, it is place outside the map */
    reg [6:0] other_position_bomb[1:0] = '{7'd127, 7'd127};
    reg [6:0] bomb_index, /* Single bomb index to calculate bomb explosion range in breakable tiles */
              bomb_offset, /* For pushing bomb */
              previous_player_index = player_index;
    wire [2:0] explode_bomb, e_explode_bomb; /* Signal bomb exploded */
    reg [25:0] explosion_display_count = 0;
    /* Reg to store calculation */
    reg player_not_on_bomb;
    reg [3:0] bomb_index_y;
    reg [6:0] explode_up[2:0]; reg [6:0] explode_left[2:0]; reg [6:0] explode_right[2:0]; reg [6:0] explode_down[2:0];
    reg [3:0] explode_left_constraint, explode_right_constraint;
    reg [6:0] bomb_indices[2:0]; reg [5:0] bomb_indices_x[2:0];
    reg [2:0] bomb_wall_collision, bomb_screen_collision, bomb_constraint;
    
    slow_clock c0 (clk, 100000, clk_1ms);
    time_bomb_explosion t0 (clk_1ms, start_bomb[0], bomb_time, explode_bomb[0]);
    time_bomb_explosion t1 (clk_1ms, start_bomb[1], bomb_time, explode_bomb[1]);
    time_bomb_explosion t2 (clk_1ms, position_bomb[2]!=127, bomb_time, explode_bomb[2]);
    time_bomb_explosion t3 (clk_1ms, start_bomb[2], bomb_time, e_explode_bomb[0]);
    time_bomb_explosion t4 (clk_1ms, start_bomb[3], bomb_time, e_explode_bomb[1]);
//    switch_debounce d1 (clk, 200, btnC, btnC_state); /* Prevent multiple placment of bomb*/
    
    assign position_bomb_o = {7'(position_bomb[1]),7'(position_bomb[0])};
    
    always @ (posedge clk) begin
        previous_player_index <= player_index; /* Store previous player index for pushing bomb */
        if (!en) begin
            after_break_tiles <= breakable_tiles;
            after_player_health <= player_health;
        end
        else if (btnC_state) begin
            /* Place the bombs under the player index if:
               - It is not in used (ouside of the map)
               - Not occupy by other bombs
               - Within number of bomb placed (Maximum limited to 3 bombs simultaneously)
            */
            previous_player_index = player_index; /* Ensure bomb is place at player index */
            player_not_on_bomb = position_bomb[0] != player_index & position_bomb[1] != player_index & position_bomb[2] != player_index;
            if (position_bomb[0] == 127 && player_not_on_bomb) begin
                position_bomb[0] <= player_index;
                start_bomb[0] <= 1;
            end
            else if (bomb_limit > 1 && position_bomb[1] == 127 && player_not_on_bomb) begin
                position_bomb[1] <= player_index;
                start_bomb[1] <= 1;
            end
            else if (bomb_limit > 2 && position_bomb[2] == 127 && player_not_on_bomb) begin
                position_bomb[2] <= player_index;
                start_bomb[2] <= 1;
            end
        end
        if (other_position_bomb[0] != other_position_bomb_i[6:0]) begin
            other_position_bomb[0] <= other_position_bomb_i[6:0];
            if (other_position_bomb[0] != 127) begin
                start_bomb[2] <= 1;
            end
            if (other_position_bomb[1] != 127) begin
                start_bomb[3] <= 1;
            end
        end
        if (explosion_display_count > 0) begin
            explosion_display_count <= explosion_display_count + (explosion_display_count < 50000000);
//            if (explosion_display_count == 50000000-1)
            if (explosion_display_count == 50000000) begin
                explosion_display <= 0;
                explosion_display_count <= 0;
                position_bomb[0] <= start_bomb[0] ? position_bomb[0] : 127;
                position_bomb[1] <= start_bomb[1] ? position_bomb[1] : 127;
            end
            if (explosion_display[player_index] == 1)
                after_player_health <= after_player_health >> 1;
        end
        else if (explode_bomb || e_explode_bomb) begin
            explosion_display_count <= 1;
            /* Determine which bomb exploded and remove it */
            if (explode_bomb[0]) begin
                bomb_index = position_bomb[0];
//                position_bomb[0] <= 127;
                start_bomb[0] <= 0;
            end
            else if (explode_bomb[1]) begin
                bomb_index = position_bomb[1];
//                position_bomb[1] <= 127;
                start_bomb[1] <= 0;
            end
            else if (explode_bomb[2]) begin
                bomb_index = position_bomb[2];
                position_bomb[2] <= 127;
            end
            else if (e_explode_bomb[0]) begin
                bomb_index = other_position_bomb[0];
                start_bomb[2] <= 0;
            end
            else if (e_explode_bomb[1]) begin
                bomb_index = other_position_bomb[1];
                start_bomb[3] <= 0;
            end
            else
                bomb_index = 127;
            /* Bomb explosion destroy nearest breakable wall within it bomb range and reduce player health if hit */
            bomb_index_y = bomb_index/12;
            explode_up = '{7'(bomb_index-3*MAX_GRID_COLUMN),7'(bomb_index-2*MAX_GRID_COLUMN),7'(bomb_index-MAX_GRID_COLUMN)};
            explode_left = '{7'(bomb_index-3),7'(bomb_index-2),7'(bomb_index-1)};
            explode_right = '{7'(bomb_index+3),7'(bomb_index+2),7'(bomb_index+1)};
            explode_down = '{7'(bomb_index+3*MAX_GRID_COLUMN),7'(bomb_index+2*MAX_GRID_COLUMN),7'(bomb_index+MAX_GRID_COLUMN)};
            explode_left_constraint = {(bomb_range > 2 & explode_left[2]/12 == bomb_index_y),(bomb_range > 1 & explode_left[1]/12 == bomb_index_y),(explode_left[0]/12 == bomb_index_y)};
            explode_right_constraint = {(bomb_range > 2 & explode_right[2]/12 == bomb_index_y),(bomb_range > 1 & explode_right[1]/12 == bomb_index_y),(explode_right[0]/12 == bomb_index_y)};
//            if (bomb_index == player_index)
//                after_player_health <= after_player_health >> 1;
            explosion_display[bomb_index] <= 1;
            /* Destroy in up direction */
            if (after_break_tiles[explode_up[0]] == 1 || wall_tiles[explode_up[0]] == 1) begin
                after_break_tiles[explode_up[0]] <= 0;
                explosion_display[explode_up[0]] <= 1;
            end
            else if (bomb_range > 1 && (after_break_tiles[explode_up[1]] == 1 || wall_tiles[explode_up[1]] == 1)) begin
                after_break_tiles[explode_up[1]] <= 0;
                explosion_display[explode_up[0]] <= 1;
                explosion_display[explode_up[1]] <= 1;
//                if (explode_up[0] == player_index)
//                    after_player_health <= after_player_health >> 1;
            end
            else if (bomb_range > 2 && (after_break_tiles[explode_up[2]] == 1 || wall_tiles[explode_up[2]] == 1)) begin
                after_break_tiles[explode_up[2]] <= 0;
                explosion_display[explode_up[0]] <= 1;
                explosion_display[explode_up[1]] <= 1;
                explosion_display[explode_up[2]] <= 1;
//                if (explode_up[0] == player_index || explode_up[1] == player_index)
//                    after_player_health <= after_player_health >> 1;
            end
            else begin
//                if (explode_up[0] == player_index || (bomb_range > 1 && explode_up[1] == player_index) || (bomb_range > 2 && explode_up[2] == player_index))
//                    after_player_health <= after_player_health >> 1;
                explosion_display[explode_up[0]] <= 1;
                explosion_display[explode_up[1]] <= bomb_range > 1 ? 1:0;
                explosion_display[explode_up[2]] <= bomb_range > 2 ? 1:0;
            end
            /* Destroy in left direction */
            if (explode_left_constraint[0] && after_break_tiles[explode_left[0]] == 1 || wall_tiles[explode_left[0]] == 1) begin
                after_break_tiles[explode_left[0]] <= 0;
                explosion_display[explode_left[0]] <= 1;
            end
            else if (explode_left_constraint[1] && (after_break_tiles[explode_left[1]] == 1 || wall_tiles[explode_left[1]] == 1)) begin
                after_break_tiles[explode_left[1]] <= 0;
                explosion_display[explode_left[0]] <= 1;
                explosion_display[explode_left[1]] <= 1;
//                if (explode_left[0] == player_index)
//                    after_player_health <= after_player_health >> 1;
            end
            else if (explode_left_constraint[2] && (after_break_tiles[explode_left[2]] == 1 || wall_tiles[explode_left[2]] == 1)) begin
                after_break_tiles[explode_left[2]] <= 0;
                explosion_display[explode_left[0]] <= 1;
                explosion_display[explode_left[1]] <= 1;
                explosion_display[explode_left[2]] <= 1;
//                if (explode_left[0] == player_index || explode_left[1] == player_index)
//                    after_player_health <= after_player_health >> 1;
            end
            else begin
//                if (bomb_index_y == player_index/12 && (explode_left[0] == player_index || explode_left[1] == player_index || explode_left[2] == player_index))
//                    after_player_health <= after_player_health >> 1;
                explosion_display[explode_left[0]] <= explode_left_constraint[0] ? 1:0;
                explosion_display[explode_left[1]] <= explode_left_constraint[1] ? 1:0;
                explosion_display[explode_left[2]] <= explode_left_constraint[2] ? 1:0;
            end
            /* Destroy in right direction */
            if (explode_right_constraint[0] && after_break_tiles[explode_right[0]] == 1 || wall_tiles[explode_right[0]] == 1) begin
                after_break_tiles[explode_right[0]] <= 0;
                explosion_display[explode_right[0]] <= 1;
            end
            else if (explode_right_constraint[1] && (after_break_tiles[explode_right[1]] == 1 || wall_tiles[explode_right[1]] == 1)) begin
                after_break_tiles[explode_right[1]] <= 0;
                explosion_display[explode_right[0]] <= 1;
                explosion_display[explode_right[1]] <= 1;
//                if (explode_right[0] == player_index)
//                    after_player_health <= after_player_health >> 1;
            end
            else if (explode_right_constraint[2] && (after_break_tiles[explode_right[2]] == 1 || wall_tiles[explode_right[2]] == 1)) begin
                after_break_tiles[explode_right[2]] <= 0;
                explosion_display[explode_right[0]] <= 1;
                explosion_display[explode_right[1]] <= 1;
                explosion_display[explode_right[2]] <= 1;
//                if (explode_right[0] == player_index || explode_right[1] == player_index)
//                    after_player_health <= after_player_health >> 1;
            end
            else begin
//                if (bomb_index_y == player_index/12 && (explode_right[0] == player_index || explode_right[1] == player_index || explode_right[2] == player_index))
//                    after_player_health <= after_player_health >> 1;
                explosion_display[explode_right[0]] <= explode_right_constraint[0] ? 1:0;
                explosion_display[explode_right[1]] <= explode_right_constraint[1] ? 1:0;
                explosion_display[explode_right[2]] <= explode_right_constraint[2] ? 1:0;
            end
            /* Destroy in down direction */
            if (after_break_tiles[explode_down[0]] == 1 || wall_tiles[explode_down[0]] == 1) begin
                after_break_tiles[explode_down[0]] <= 0;
                explosion_display[explode_down[0]] <= 1;
            end
            else if (bomb_range > 1 && (after_break_tiles[explode_down[1]] == 1 || wall_tiles[explode_down[1]] == 1)) begin
                after_break_tiles[explode_down[1]] <= 0;
                explosion_display[explode_down[0]] <= 1;
                explosion_display[explode_down[1]] <= 1;
//                if (explode_down[0] == player_index)
//                    after_player_health <= after_player_health >> 1;
            end
            else if (bomb_range > 2 && (after_break_tiles[explode_down[2]] == 1 || wall_tiles[explode_down[2]] == 1)) begin
                after_break_tiles[explode_down[2]] <= 0;
                explosion_display[explode_down[0]] <= 1;
                explosion_display[explode_down[1]] <= 1;
                explosion_display[explode_down[2]] <= 1;
//                if (explode_down[0] == player_index || explode_down[1] == player_index)
//                    after_player_health <= after_player_health >> 1;
            end
            else begin
//                if (explode_down[0] == player_index || explode_down[1] == player_index || explode_down[2] == player_index)
//                    after_player_health <= after_player_health >> 1;
                explosion_display[explode_down[0]] <= 1;
                explosion_display[explode_down[1]] <= bomb_range > 1 ? 1:0;
                explosion_display[explode_down[2]] <= bomb_range > 2 ? 1:0;
            end
        end
        /* Ability to push bomb forward */
        else if (push_bomb_ability && player_index != previous_player_index && (player_index == position_bomb[0] || player_index == position_bomb[1] || player_index == position_bomb[2])) begin
            /* Store player direction */
            bomb_offset = -(previous_player_index - player_index);
            /* Store calculations*/
            bomb_indices = '{7'(position_bomb[2] + bomb_offset),7'(position_bomb[1] + bomb_offset),7'(position_bomb[0] + bomb_offset)};
            bomb_indices_x = '{6'(bomb_indices[2]%12),6'(bomb_indices[1]%12),6'(bomb_indices[0]%12)};
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
                    position_bomb[0] <= bomb_indices[0];
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