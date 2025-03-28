`timescale 1ns / 1ps

module OLED_to_VGA (
    input clk_100MHz,
    input [15:0] pixel_data,
    input [15:0] score,
    input [12:0] pixel_index,
    output hsync,
    vsync,
    output reg [11:0] rgb
);
  // Border parameters
  parameter BORDER_WIDTH = 4;
  parameter BORDER_COLOR = 12'hFFF;

  wire video_on;
  wire [9:0] x;
  wire [9:0] y;
  wire p_tick;

  // OLED dimensions
  parameter OLED_WIDTH = 96;
  parameter OLED_HEIGHT = 64;

  // VGA dimensions
  parameter VGA_WIDTH = 640;
  parameter VGA_HEIGHT = 480;

  // Calculate scaling factors - use power two
  parameter SCALE_X = 4;
  parameter SCALE_Y = 4;

  // Calculate offsets to center the display
  parameter X_OFFSET = (VGA_WIDTH - (OLED_WIDTH * SCALE_X)) / 2;
  parameter Y_OFFSET = (VGA_HEIGHT - (OLED_HEIGHT * SCALE_Y)) / 2;

  // Frame buffer to store complete OLED image
  (* ram_style = "block" *) reg [12:0] frame_buffer[0:6143];

  // Adjust VGA coordinates to account for centering offset
  wire [9:0] adjusted_x = (x >= X_OFFSET && x < X_OFFSET + (OLED_WIDTH * SCALE_X)) ? x - X_OFFSET : 10'd0;
  wire [9:0] adjusted_y = (y >= Y_OFFSET && y < Y_OFFSET + (OLED_HEIGHT * SCALE_Y)) ? y - Y_OFFSET : 10'd0;

  // Calculate which OLED pixel this VGA pixel belongs to
  wire [6:0] vga_to_oled_x = adjusted_x >> 2;
  wire [5:0] vga_to_oled_y = adjusted_y >> 2;
  wire [12:0] buff_index = vga_to_oled_y * OLED_WIDTH + vga_to_oled_x;

  reg reset;
  
//  initial begin
//    reset = 1;
//    #5; 
//    reset = 0;
//  end
  
  // Instantiate the VGA controller
  vga_controller vga_c (
      .clk_100MHz(clk_100MHz),
      .reset(reset),
      .hsync(hsync),
      .vsync(vsync),
      .video_on(video_on),
      .p_tick(p_tick),
      .x(x),
      .y(y)
  );
  
  
  always @(posedge clk_100MHz) begin
      frame_buffer[pixel_index] <= {pixel_data[4:1], pixel_data[10:7], pixel_data[15:12]};
  end
  
  wire is_in_display_area = (x >= X_OFFSET && x < (X_OFFSET + OLED_WIDTH * SCALE_X) && 
                            y >= Y_OFFSET && y < (Y_OFFSET + OLED_HEIGHT * SCALE_Y));
  wire is_in_score_area = (x >= X_OFFSET && x < (X_OFFSET + OLED_WIDTH * SCALE_X) && 
                            y >= Y_OFFSET + OLED_HEIGHT * SCALE_Y && y < (Y_OFFSET + OLED_HEIGHT * SCALE_Y + 16));
  wire is_in_left_right_border = ((x >= X_OFFSET - BORDER_WIDTH && x < X_OFFSET) ||
                                 (x >= X_OFFSET + OLED_WIDTH * SCALE_X && x < X_OFFSET + OLED_WIDTH * SCALE_X + BORDER_WIDTH)) &&
                                (y >= Y_OFFSET - BORDER_WIDTH && y < Y_OFFSET + OLED_HEIGHT * SCALE_Y + BORDER_WIDTH);
  
  wire is_in_top_bottom_border = ((y >= Y_OFFSET - BORDER_WIDTH && y < Y_OFFSET) ||
                                 (y >= Y_OFFSET + OLED_HEIGHT * SCALE_Y && y < Y_OFFSET + OLED_HEIGHT * SCALE_Y + BORDER_WIDTH)) &&
                                (x >= X_OFFSET - BORDER_WIDTH && x < X_OFFSET + OLED_WIDTH * SCALE_X + BORDER_WIDTH);
  
  wire is_in_border = is_in_left_right_border || is_in_top_bottom_border;
  
  always @(posedge p_tick) begin
    if (~video_on)
      rgb <= 12'h000;
    else if (is_in_display_area)
      rgb <= frame_buffer[buff_index];
    else if (is_in_score_area)
      rgb <= 12'hf0f;
    else if (is_in_border)
      rgb <= BORDER_COLOR;
    else
      rgb <= 12'h000;
  end

endmodule
