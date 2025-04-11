`timescale 1ns / 1ps

module is_collision (
    input [6:0] cur_index,
    input [95:0] wall_tiles,
    input [95:0] breakable_tiles,
    input [2:0] direction,
    input en,
    output reg [6:0] new_index
);

  parameter GRID_WIDTH = 12;
  parameter GRID_HEIGHT = 8;
  
  // Extract X/Y coordinates from current index
  wire [3:0] x_cur = cur_index % GRID_WIDTH;
  wire [3:0] y_cur = cur_index / GRID_WIDTH;
  
  // Temporary variables for new coordinates
  reg [3:0] x_new, y_new;

  always @(*) begin
    // Default to current position
    x_new = x_cur;
    y_new = y_cur;
    
    if (en) begin
      // Process movement based on direction
      case (direction)
        1: y_new = (y_cur > 0) ? y_cur - 1 : y_cur;                  // UP
        2: x_new = (x_cur < GRID_WIDTH - 1) ? x_cur + 1 : x_cur;     // RIGHT
        3: y_new = (y_cur < GRID_HEIGHT - 1) ? y_cur + 1 : y_cur;    // DOWN
        4: x_new = (x_cur > 0) ? x_cur - 1 : x_cur;                  // LEFT
        default: begin
          // No movement
        end
      endcase

      // Calculate new index
      new_index = y_new * GRID_WIDTH + x_new;

      // Check for collision with walls or breakable blocks
      if (wall_tiles[new_index] || breakable_tiles[new_index]) begin
        // If collision detected, stay at current position
        new_index = cur_index;
      end
    end else begin
      // If not enabled, stay at current position
      new_index = cur_index;
    end
  end

endmodule
