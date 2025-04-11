`timescale 1ns / 1ps

module BombDisplay #(
    parameter BOMB_VOFFSET = 20,  // Updated to match OLED_to_VGA.v
    parameter BOMB_HOFFSET = 20   // Updated to match OLED_to_VGA.v
) (
    input clk,
    input [9:0] x_in,
    input [9:0] y_in,
    input [3:0] bombs,  // 4 bits represent up to 4 bombs (1111 = 4 bombs, 0111 = 3 bombs, etc.)
    output reg in_bomb_region,
    output reg pixel_on
);
    import sprites::*;
    
    // Display parameters
    parameter BOMB_SIZE = 8;       // 8x8 sprite
    parameter BOMB_SCALE_2N = 2;   // Scale factor as 2^n (making bombs 4x larger)
    parameter BOMB_SPACING = 4;    // Space between bomb icons
    parameter MAX_BOMBS = 4;       // Maximum number of bombs
    
    // Pre-calculate constants for efficiency
    localparam EFFECTIVE_BOMB_SIZE = BOMB_SIZE << BOMB_SCALE_2N;
    localparam BOMB_STRIDE = EFFECTIVE_BOMB_SIZE + BOMB_SPACING;
    localparam TOTAL_WIDTH = BOMB_STRIDE * MAX_BOMBS - BOMB_SPACING;
    
    // Unpack the bomb sprite data into individual rows for easier access
    wire [7:0] bomb_sprite_rows [0:7];
    assign bomb_sprite_rows[0] = BOMB_SPRITE_DATA[63:56];
    assign bomb_sprite_rows[1] = BOMB_SPRITE_DATA[55:48];
    assign bomb_sprite_rows[2] = BOMB_SPRITE_DATA[47:40];
    assign bomb_sprite_rows[3] = BOMB_SPRITE_DATA[39:32];
    assign bomb_sprite_rows[4] = BOMB_SPRITE_DATA[31:24];
    assign bomb_sprite_rows[5] = BOMB_SPRITE_DATA[23:16];
    assign bomb_sprite_rows[6] = BOMB_SPRITE_DATA[15:8];
    assign bomb_sprite_rows[7] = BOMB_SPRITE_DATA[7:0];
    
    // Registers for internal processing
    reg [9:0] x_pos, y_pos;
    reg [2:0] bomb_index;
    reg [2:0] sprite_row;
    reg [2:0] sprite_col;
    reg in_region;
    
    // Pipeline registers - Stage 1
    reg stage1_in_region;
    reg [9:0] x_pos_stage1, y_pos_stage1;
    reg [2:0] bomb_index_stage1;
    reg [9:0] rel_x_stage1, rel_y_stage1;
    reg bomb_exists_stage1;
    
    // Pipeline registers - Stage 2
    reg [2:0] sprite_row_stage2;
    reg [2:0] sprite_col_stage2;
    reg in_sprite_area_stage2;
    reg bomb_exists_stage2;
    
    // Sprite data handling
    reg [7:0] sprite_row_data;
    wire sprite_bit;
    
    // Access sprite data based on row
    always @* begin
        sprite_row_data = bomb_sprite_rows[sprite_row_stage2];
    end
    
    // Get the specific bit from the row
    assign sprite_bit = (sprite_row_data >> (7-sprite_col_stage2)) & 1'b1;
    
    // Stage 1: Region detection and bomb index calculation
    always @(posedge clk) begin
        // Check if we're in the bomb display region
        stage1_in_region <= (y_in >= BOMB_VOFFSET) && 
                            (y_in < BOMB_VOFFSET + EFFECTIVE_BOMB_SIZE) &&
                            (x_in >= BOMB_HOFFSET) && 
                            (x_in < BOMB_HOFFSET + TOTAL_WIDTH);
        
        // Calculate position within the overall bomb display area
        x_pos_stage1 <= x_in - BOMB_HOFFSET;
        y_pos_stage1 <= y_in - BOMB_VOFFSET;
        
        // Calculate which bomb we're looking at (0-3, 0 is leftmost) using if-else chain
        if (x_pos_stage1 < BOMB_STRIDE)
            bomb_index_stage1 <= 3'd0;
        else if (x_pos_stage1 < (2 * BOMB_STRIDE))
            bomb_index_stage1 <= 3'd1;
        else if (x_pos_stage1 < (3 * BOMB_STRIDE))
            bomb_index_stage1 <= 3'd2;
        else
            bomb_index_stage1 <= 3'd3;
        
        // Calculate position relative to the current bomb's top-left corner
        rel_x_stage1 <= x_pos_stage1 - (bomb_index_stage1 * BOMB_STRIDE);
        rel_y_stage1 <= y_pos_stage1;
        
        // Check if this bomb exists based on 'bombs' input
        bomb_exists_stage1 <= (bomb_index_stage1 < MAX_BOMBS) ? bombs[bomb_index_stage1] : 1'b0;
        
        // Output signal for the region detection
        in_bomb_region <= stage1_in_region;
    end
    
    // Stage 2: Sprite coordinate calculation
    always @(posedge clk) begin
        if (stage1_in_region) begin
            // Check if we're within an actual bomb sprite area (not in spacing)
            in_sprite_area_stage2 <= (rel_x_stage1 < EFFECTIVE_BOMB_SIZE);
            
            // Scale down to get the sprite row and column
            sprite_row_stage2 <= rel_y_stage1 >> BOMB_SCALE_2N;
            sprite_col_stage2 <= rel_x_stage1 >> BOMB_SCALE_2N;
            
            // Propagate the bomb existence flag
            bomb_exists_stage2 <= bomb_exists_stage1;
        end else begin
            in_sprite_area_stage2 <= 0;
            bomb_exists_stage2 <= 0;
        end
    end
    
    // Stage 3: Generate pixel output based on sprite data
    always @(posedge clk) begin
        if (stage1_in_region && in_sprite_area_stage2 && bomb_exists_stage2) begin
            // Set pixel on if the sprite bit is 1
            pixel_on <= sprite_bit;
        end else begin
            pixel_on <= 0;
        end
    end
endmodule
