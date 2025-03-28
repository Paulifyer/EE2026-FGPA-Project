`timescale 1ns / 1ps

module is_collision (
    input [7:0] x_cur,
    input [7:0] y_cur,
    input [95:0] wall_tiles,
    input [95:0] breakable_tiles,
    input [2:0] direction,
    input en,
    output reg [7:0] x_out,
    output reg [7:0] y_out
);

  parameter width = 12;
  parameter height = 8;

  reg signed [7:0] x_new;
  reg signed [7:0] y_new;

  reg is_collision;
  reg is_edge;

  always @(direction) begin
    case (direction)
      3'b001: begin  // up
        x_new = x_cur;
        y_new = y_cur - 1;
      end
      3'b010: begin  // right
        x_new = x_cur + 1;
        y_new = y_cur;
      end
      3'b011: begin  // down
        x_new = x_cur;
        y_new = y_cur + 1;
      end
      3'b100: begin  // left
        x_new = x_cur - 1;
        y_new = y_cur;
      end
      default: begin
        x_new = x_cur;
        y_new = y_cur;
      end
    endcase

    is_collision = wall_tiles[y_new*width+x_new] || breakable_tiles[y_new*width+x_new];
    is_edge = (x_new < 0) || (x_new >= width) || (y_new < 0) || (y_new == height);

    x_out = en ? (is_collision || is_edge) ? x_cur : x_new : x_cur;
    y_out = en ? (is_collision || is_edge) ? y_cur : y_new : x_cur;
  end



endmodule
