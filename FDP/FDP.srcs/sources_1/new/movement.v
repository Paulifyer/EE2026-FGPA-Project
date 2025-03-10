`timescale 1ns / 1ps

module Task_4D(
    input clk, btnD, btnU, btnL, btnR, btnC, en,
    input [12:0] pixel_index,
    input [95:0] wall_tiles, // Changed from [6:0] to [95:0] to account for all 96 tiles
    output [15:0] pixel_data
    );


    reg [32:0] counter1p0k;
    reg [3:0] move;
    reg [3:0] move_ghost;
    reg out1p0k;
    reg [7:0] greenX;
    reg [7:0] greenY;
    reg [95:0] bomb_tiles;
    
    // Define tile dimensions
    parameter TILE_WIDTH = 8;  // 96/12 = 8 pixels per tile width
    parameter TILE_HEIGHT = 8; // 64/8 = 8 pixels per tile height
    parameter GRID_WIDTH = 12;
    parameter GRID_HEIGHT = 8;
     
    drawCordinate draw (pixel_index, greenX, greenY, wall_tiles, bomb_tiles, pixel_data);    
  
            
    initial begin 
        out1p0k = 0; 
        greenX = 0;
        greenY = 56;
        move = 0;
        move_ghost = 0;
        bomb_tiles = 0;
    end

    always @(posedge clk) begin
        counter1p0k <= (counter1p0k != 16666660) ? counter1p0k + 1 :0;
        out1p0k <= (counter1p0k == 0) ? ~out1p0k: out1p0k;
        move <= en ? btnU ? 1 : (btnR ? 2 : (btnD ? 3 : (btnL ? 4: 0))) : 0;
        move_ghost <= (counter1p0k % 4 == 0) ? $random % 4 : move_ghost;
        bomb_tiles <= btnC ? (bomb_tiles | (1 << ((greenY / TILE_HEIGHT) * GRID_WIDTH + (greenX / TILE_WIDTH)))) : bomb_tiles;
    end
    
    // Simplified function to check if a position would hit a wall
    function is_wall;
        input [7:0] x;
        input [7:0] y;
        input [2:0] direction; // 1=Up, 2=Right, 3=Down, 4=Left
        reg [3:0] next_tile_x;
        reg [3:0] next_tile_y;
        reg [6:0] next_tile_index;
        reg [4:0] curr_tile_x;
        reg [3:0] curr_tile_y;
        begin
            // Calculate the current tile
            curr_tile_x = x / TILE_WIDTH;
            curr_tile_y = y / TILE_HEIGHT;
            
            // Calculate the next tile based on direction
            case(direction)
                1: begin // Up
                    next_tile_x = curr_tile_x;
                    next_tile_y = curr_tile_y - 1;
                end
                2: begin // Right
                    next_tile_x = curr_tile_x + 1;
                    next_tile_y = curr_tile_y;
                end
                3: begin // Down
                    next_tile_x = curr_tile_x;
                    next_tile_y = curr_tile_y + 1;
                end
                4: begin // Left
                    next_tile_x = curr_tile_x - 1;
                    next_tile_y = curr_tile_y;
                end
            endcase
            
            // Check if the next tile is within bounds and is a wall
            if (next_tile_x < GRID_WIDTH && next_tile_y < GRID_HEIGHT && 
                next_tile_x >= 0 && next_tile_y >= 0) begin
                next_tile_index = (next_tile_y * GRID_WIDTH) + next_tile_x;
                is_wall = wall_tiles[next_tile_index];
            end else
                is_wall = 1; // Out of bounds counts as a wall
        end
    endfunction

    always @(posedge clk1p0k) begin
        if (en == 1) begin
            case (move)
                0: begin // No movement
                    // Do nothing
                end
                1: begin // Up
                    // Calculate new position - move one full tile up
                    if (greenY >= TILE_HEIGHT && !is_wall(greenX, greenY, 1)) begin
                        greenY = greenY - TILE_HEIGHT;
                    end
                end
                2: begin // Right
                    // Calculate new position - move one full tile right
                    if (greenX <= (96 - TILE_WIDTH * 2) && !is_wall(greenX, greenY, 2)) begin
                        greenX = greenX + TILE_WIDTH;
                    end
                end
                3: begin // Down
                    // Calculate new position - move one full tile down
                    if (greenY <= (64 - TILE_HEIGHT * 2) && !is_wall(greenX, greenY, 3)) begin
                        greenY = greenY + TILE_HEIGHT;
                    end
                end
                4: begin // Left
                    // Calculate new position - move one full tile left
                    if (greenX >= TILE_WIDTH && !is_wall(greenX, greenY, 4)) begin
                        greenX = greenX - TILE_WIDTH;
                    end
                end
            endcase
            case (move_ghost)
                0: begin // No movement
                    // Do nothing
                end
                1: begin // Up
                    // Calculate new position - move one full tile up
                    if (greenY >= TILE_HEIGHT) begin
                        greenY = greenY - TILE_HEIGHT;
                    end
                end
                2: begin // Right
                    // Calculate new position - move one full tile right
                    if (greenX <= (96 - TILE_WIDTH * 2)) begin
                        greenX = greenX + TILE_WIDTH;
                    end
                end
                3: begin // Down
                    // Calculate new position - move one full tile down
                    if (greenY <= (64 - TILE_HEIGHT * 2)) begin
                        greenY = greenY + TILE_HEIGHT;
                    end
                end
                4: begin // Left
                    // Calculate new position - move one full tile left
                    if (greenX >= TILE_WIDTH) begin
                        greenX = greenX - TILE_WIDTH;
                    end
                end
            endcase
        end else begin
            greenX = 0;
            greenY = 56; // Make sure this matches the initial value
        end
    end
    
    assign clk1p0k = out1p0k;

endmodule
