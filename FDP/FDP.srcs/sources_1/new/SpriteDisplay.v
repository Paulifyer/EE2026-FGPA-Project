`timescale 1ns / 1ps

module SpriteCountDisplay #(
    parameter SPRITE_VOFFSET = 20,
    parameter SPRITE_HOFFSET = 20
) (
    input clk,
    input [9:0] x_in,
    input [9:0] y_in,
    input [3:0] count,  // 4 bits represent up to 4 sprites (1111 = 4 sprites, 0111 = 3 sprites, etc.)
    input [63:0] sprite_data,  // Input sprite data (8x8 sprite as 64 bits)
    output reg in_sprite_region,
    output reg pixel_on
);
    import sprites::*;
    
    // Display parameters
    parameter SPRITE_SIZE = 8;       // 8x8 sprite
    parameter SPRITE_SCALE_2N = 2;   // Scale factor as 2^n (making sprites 4x larger)
    parameter SPRITE_SPACING = 4;    // Space between sprite icons
    parameter MAX_SPRITES = 4;       // Maximum number of sprites
    
    // Pre-calculate constants for efficiency
    localparam EFFECTIVE_SPRITE_SIZE = SPRITE_SIZE << SPRITE_SCALE_2N;
    localparam SPRITE_STRIDE = EFFECTIVE_SPRITE_SIZE + SPRITE_SPACING;
    localparam TOTAL_WIDTH = SPRITE_STRIDE * MAX_SPRITES - SPRITE_SPACING;
    
    // Unpack the sprite data into individual rows for easier access
    wire [7:0] sprite_rows [0:7];
    assign sprite_rows[0] = sprite_data[63:56];
    assign sprite_rows[1] = sprite_data[55:48];
    assign sprite_rows[2] = sprite_data[47:40];
    assign sprite_rows[3] = sprite_data[39:32];
    assign sprite_rows[4] = sprite_data[31:24];
    assign sprite_rows[5] = sprite_data[23:16];
    assign sprite_rows[6] = sprite_data[15:8];
    assign sprite_rows[7] = sprite_data[7:0];
    
    // Pipeline registers - Stage 1
    reg stage1_in_region;
    reg [9:0] x_pos_stage1, y_pos_stage1;
    reg [2:0] sprite_index_stage1;
    reg [9:0] rel_x_stage1, rel_y_stage1;
    reg sprite_exists_stage1;
    
    // Pipeline registers - Stage 2
    reg [2:0] sprite_row_stage2;
    reg [2:0] sprite_col_stage2;
    reg in_sprite_area_stage2;
    reg sprite_exists_stage2;
    
    // Sprite data handling
    reg [7:0] sprite_row_data;
    wire sprite_bit;
    
    // Access sprite data based on row
    always @* begin
        sprite_row_data = sprite_rows[sprite_row_stage2];
    end
    
    // Get the specific bit from the row
    assign sprite_bit = (sprite_row_data >> (7-sprite_col_stage2)) & 1'b1;
    
    // Stage 1: Region detection and sprite index calculation
    always @(posedge clk) begin
        // Check if we're in the sprite display region
        stage1_in_region <= (y_in >= SPRITE_VOFFSET) && 
                            (y_in < SPRITE_VOFFSET + EFFECTIVE_SPRITE_SIZE) &&
                            (x_in >= SPRITE_HOFFSET) && 
                            (x_in < SPRITE_HOFFSET + TOTAL_WIDTH);
        
        // Calculate position within the overall sprite display area
        x_pos_stage1 <= x_in - SPRITE_HOFFSET;
        y_pos_stage1 <= y_in - SPRITE_VOFFSET;
        
        // Calculate which sprite we're looking at (0-3, 0 is leftmost) using if-else chain
        if (x_pos_stage1 < SPRITE_STRIDE)
            sprite_index_stage1 <= 3'd0;
        else if (x_pos_stage1 < (2 * SPRITE_STRIDE))
            sprite_index_stage1 <= 3'd1;
        else if (x_pos_stage1 < (3 * SPRITE_STRIDE))
            sprite_index_stage1 <= 3'd2;
        else
            sprite_index_stage1 <= 3'd3;
        
        // Calculate position relative to the current sprite's top-left corner
        rel_x_stage1 <= x_pos_stage1 - (sprite_index_stage1 * SPRITE_STRIDE);
        rel_y_stage1 <= y_pos_stage1;
        
        // Check if this sprite exists based on 'count' input
        sprite_exists_stage1 <= (sprite_index_stage1 < MAX_SPRITES) ? count[sprite_index_stage1] : 1'b0;
        
        // Output signal for the region detection
        in_sprite_region <= stage1_in_region;
    end
    
    // Stage 2: Sprite coordinate calculation
    always @(posedge clk) begin
        if (stage1_in_region) begin
            // Check if we're within an actual sprite area (not in spacing)
            in_sprite_area_stage2 <= (rel_x_stage1 < EFFECTIVE_SPRITE_SIZE);
            
            // Scale down to get the sprite row and column
            sprite_row_stage2 <= rel_y_stage1 >> SPRITE_SCALE_2N;
            sprite_col_stage2 <= rel_x_stage1 >> SPRITE_SCALE_2N;
            
            // Propagate the sprite existence flag
            sprite_exists_stage2 <= sprite_exists_stage1;
        end else begin
            in_sprite_area_stage2 <= 0;
            sprite_exists_stage2 <= 0;
        end
    end
    
    // Stage 3: Generate pixel output based on sprite data
    always @(posedge clk) begin
        if (stage1_in_region && in_sprite_area_stage2 && sprite_exists_stage2) begin
            // Set pixel on if the sprite bit is 1
            pixel_on <= sprite_bit;
        end else begin
            pixel_on <= 0;
        end
    end
endmodule