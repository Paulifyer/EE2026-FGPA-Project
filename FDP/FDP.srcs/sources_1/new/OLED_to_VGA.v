`timescale 1ns / 1ps

module OLED_to_VGA (
    input clk,
    input [15:0] pixel_data,
    input [15:0] score,
    input [12:0] pixel_index,
    output hsync,
    vsync,
    output reg [11:0] rgb
);
  // Border parameters
  parameter BORDER_WIDTH = 4;

  // Color constants
  parameter COLOUR_BLACK = 12'h000;
  parameter COLOUR_WHITE = 12'hFFF;

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
  
  // Register the read address for Block RAM inference
  reg [12:0] buff_index_reg;
  // Register the output from frame buffer
  reg [12:0] frame_buff_data;
  // Register display area flag
  reg is_in_display_area_reg;
  
  always @(posedge clk) begin
    buff_index_reg <= buff_index;
    frame_buff_data <= frame_buffer[buff_index_reg];
    is_in_display_area_reg <= is_in_display_area;
  end

  reg reset;

  // Instantiate the VGA controller
  vga_controller vga_c (
      .clk(clk),
      .reset(reset),
      .hsync(hsync),
      .vsync(vsync),
      .video_on(video_on),
      .p_tick(p_tick),
      .x(x),
      .y(y)
  );

  // Separate write and read operations for the frame buffer
  always @(posedge clk) begin
    // Write operation
    frame_buffer[pixel_index] <= {pixel_data[4:1], pixel_data[10:7], pixel_data[15:12]};
  end

  wire is_in_display_area = (x >= X_OFFSET && x < (X_OFFSET + OLED_WIDTH * SCALE_X) && 
                            y >= Y_OFFSET && y < (Y_OFFSET + OLED_HEIGHT * SCALE_Y));

  wire is_in_left_right_border = ((x >= X_OFFSET - BORDER_WIDTH && x < X_OFFSET) ||
                                 (x >= X_OFFSET + OLED_WIDTH * SCALE_X && x < X_OFFSET + OLED_WIDTH * SCALE_X + BORDER_WIDTH)) &&
                                (y >= Y_OFFSET - BORDER_WIDTH && y < Y_OFFSET + OLED_HEIGHT * SCALE_Y + BORDER_WIDTH);

  wire is_in_top_bottom_border = ((y >= Y_OFFSET - BORDER_WIDTH && y < Y_OFFSET) ||
                                 (y >= Y_OFFSET + OLED_HEIGHT * SCALE_Y && y < Y_OFFSET + OLED_HEIGHT * SCALE_Y + BORDER_WIDTH)) &&
                                (x >= X_OFFSET - BORDER_WIDTH && x < X_OFFSET + OLED_WIDTH * SCALE_X + BORDER_WIDTH);

  wire is_in_border = is_in_left_right_border || is_in_top_bottom_border;

  // Convert binary score to 4-digit BCD (assumes score < 10000)
  wire [3:0] digit0, digit1, digit2, digit3;

  wire score_pixel_active;

  wire is_in_score_area;

  // Instantiate the BCD converter module
  BcdConverter bcd_inst (
      .score (score),
      .digit0(digit0),
      .digit1(digit1),
      .digit2(digit2),
      .digit3(digit3)
  );

  // Define score display parameters
  parameter SCORE_VOFFSET = 370;  // Top offset for score display
  parameter SCORE_HOFFSET = 125;  // Left offset for score display

  // Instantiate the score module with custom offsets:
  ScoreOnPixel #(
      .SCORE_VOFFSET(SCORE_VOFFSET),
      .SCORE_HOFFSET(SCORE_HOFFSET) 
  ) sp_inst (
      .clk            (clk),
      .x_in           (x),
      .y_in           (y),
      .s0             (digit0),
      .s1             (digit1),
      .s2             (digit2),
      .s3             (digit3),
      .in_score_region(is_in_score_area),
      .pixel_on       (score_pixel_active)
  );


  always @(posedge clk) begin
    if (~video_on) rgb <= COLOUR_BLACK;
    else if (is_in_display_area_reg) rgb <= frame_buff_data;  // Use registered data
    else if (is_in_border) rgb <= COLOUR_WHITE;
    else if (is_in_score_area && score_pixel_active) rgb <= COLOUR_WHITE;
    else if (is_in_score_area) rgb <= COLOUR_BLACK;
    else rgb <= COLOUR_BLACK;  // Everything else black
  end

endmodule
